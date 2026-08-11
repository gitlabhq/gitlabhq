# frozen_string_literal: true

module MergeRequests
  class KeepAroundRefsService
    include BaseServiceUtility
    include Gitlab::ExclusiveLeaseHelpers

    # Erring long is deliberate: a lease that expires while its write is still running
    # lets a second job overlap it, which is the Praefect reference-transaction race the
    # lease exists to prevent. One held after a crash only costs a few of the 20 retries.
    LEASE_TTL = 5.minutes.to_i

    def initialize(project_ids:, shas:, source:)
      @project_ids = Array(project_ids)
      @shas = Array(shas).compact
      @source = source
    end

    def execute
      return if @shas.empty?

      # Split per project rather than per job: a fork merge request covers both projects,
      # so gating on the job would let one project's flag change the other's. This is the
      # only read of the flag; the decision is passed down so a second read cannot differ.
      new_projects, old_projects = projects.partition do |project|
        Feature.enabled?(:retry_failed_keep_around_ref_writes, project)
      end

      old_result = old_execute(old_projects)

      # A job with no enabled project keeps the return value it has today.
      return old_result if new_projects.empty?

      new_execute(new_projects)
    end

    private

    # `Gitlab::Git::KeepAround` swallows a failed write on this path, so there is
    # nothing to report and nothing to retry.
    def old_execute(projects)
      projects.map(&:repository).each do |repo|
        repo.keep_around(*@shas, source: @source)
      end
    end

    # A success carries no SHAs: the refs actually written are not knowable here, since
    # `Gitlab::Git::KeepAround` legitimately skips a SHA that is already kept around or
    # whose commit is gone, and reports neither.
    def new_execute(projects)
      unwritten = projects.flat_map { |project| write_refs(project) }.uniq

      return ServiceResponse.success if unwritten.empty?

      ServiceResponse.error(
        message: 'Keep-around references were not written',
        payload: { unwritten_shas: unwritten }
      )
    end

    def projects
      Project.id_in(@project_ids.uniq)
    end

    # A Sidekiq retry never runs the client middleware that takes the worker's
    # `deduplicate` key, and its cleanup frees the key an identical queued job holds.
    # Now that the worker raises, hold a lease so two writes cannot overlap.
    def write_refs(project)
      in_lock(lease_key(project), ttl: LEASE_TTL, retries: 0) do
        failed = project.repository.keep_around(*@shas, source: @source, retry_failed_writes: true)
        log_unwritten(project, failed, message: 'Keep-around reference write failed') if failed.present?

        failed
      end
    rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
      # Reported rather than treated as a success, because a success would drop the
      # write for good if the lease holder were interrupted before finishing.
      log_unwritten(project, @shas.uniq, message: 'Keep-around reference write skipped, lease already held')

      @shas.uniq
    end

    # Logged here, not in the worker, which sees only the job's full `project_ids` and
    # cannot attribute a SHA to a repository. The cause rides in the message because
    # Labkit's field standardization deprecates `reason`.
    def log_unwritten(project, shas, message:)
      Gitlab::AppLogger.warn(
        message: message,
        project_id: project.id,
        shas: shas,
        source: @source
      )
    end

    # Keyed on the project and the SHAs rather than on the job arguments, since it is
    # the ref write that must not overlap. `@source` is left out so two sources writing
    # the same refs contend rather than race.
    def lease_key(project)
      digest = Digest::SHA256.hexdigest([project.id, @shas.uniq.sort].join(':'))

      "merge_requests:keep_around_refs:#{digest}"
    end
  end
end
