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

    # A success carries no SHAs: the refs actually written are not knowable here, since
    # `Gitlab::Git::KeepAround` legitimately skips a SHA that is already kept around or
    # whose commit is gone, and reports neither.
    def execute
      return ServiceResponse.success if @shas.empty?

      unwritten = projects.flat_map { |project| write_refs(project) }.uniq

      return ServiceResponse.success if unwritten.empty?

      ServiceResponse.error(
        message: 'Keep-around references were not written',
        payload: { unwritten_shas: unwritten }
      )
    end

    private

    def projects
      Project.id_in(@project_ids.uniq)
    end

    # A Sidekiq retry never runs the client middleware that takes the worker's
    # `deduplicate` key, and its cleanup frees the key an identical queued job holds.
    # The worker raises to retry, so a lease is what stops two writes overlapping.
    def write_refs(project)
      in_lock(lease_key(project), ttl: LEASE_TTL, retries: 0) do
        failed = project.repository.keep_around(*@shas, source: @source)
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
