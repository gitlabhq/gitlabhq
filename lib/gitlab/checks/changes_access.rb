# frozen_string_literal: true

module Gitlab
  module Checks
    class ChangesAccess
      ATTRIBUTES = %i[user_access project protocol changes logger].freeze

      attr_reader(*ATTRIBUTES)

      def initialize(
        changes, user_access:, project:, protocol:, logger:
      )
        @changes = changes
        @user_access = user_access
        @project = project
        @protocol = protocol
        @logger = logger
      end

      def validate!
        return if changes.empty?

        single_access_checks!

        logger.log_timed("Running checks for #{changes.length} changes") do
          bulk_access_checks!
        end

        true
      end

      # All commits which have been newly introduced via any of the given
      # changes. This set may also contain commits which are not referenced by
      # any of the new revisions.
      def commits
        newrevs = @changes.map do |change|
          newrev = change[:newrev]
          newrev unless newrev.blank? || Gitlab::Git.blank_ref?(newrev)
        end.compact

        return [] if newrevs.empty?

        @commits ||= project.repository.new_commits(newrevs, allow_quarantine: true)
      end

      # All commits which have been newly introduced via the given revision.
      def commits_for(newrev)
        commits_by_id = commits.index_by(&:id)

        result = []
        pending = Set[newrev]

        # We go up the parent chain of our newrev and collect all commits which
        # are new. In case a commit's ID cannot be found in the set of new
        # commits, then it must already be a preexisting commit.
        while pending.any?
          rev = pending.first
          pending.delete(rev)

          # Remove the revision from commit candidates such that we don't walk
          # it multiple times. If the hash doesn't contain the revision, then
          # we have either already walked the commit or it's not new.
          commit = commits_by_id.delete(rev)
          next if commit.nil?

          # Only add the parent ID to the pending set if we actually know its
          # commit to guards us against readding an ID which we have already
          # queued up before.
          commit.parent_ids.each do |parent_id|
            pending.add(parent_id) if commits_by_id.has_key?(parent_id)
          end

          result << commit
        end

        result
      end

      protected

      def single_access_checks!
        # Iterate over all changes to find if user allowed all of them to be applied
        changes.each do |change|
          commits = Gitlab::Lazy.new { commits_for(change[:newrev]) } if Feature.enabled?(:changes_batch_commits)

          # If user does not have access to make at least one change, cancel all
          # push by allowing the exception to bubble up
          Checks::SingleChangeAccess.new(
            change,
            user_access: user_access,
            project: project,
            protocol: protocol,
            logger: logger,
            commits: commits
          ).validate!
        end
      end

      def bulk_access_checks!
        Gitlab::Checks::LfsCheck.new(self).validate!
      end
    end
  end
end
