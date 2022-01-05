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
        allow_quarantine = true

        newrevs = @changes.map do |change|
          oldrev = change[:oldrev]
          newrev = change[:newrev]

          next if blank_rev?(newrev)

          # In case any of the old revisions is blank, then we cannot reliably
          # detect which commits are new for a given change when enumerating
          # objects via the object quarantine directory given that the client
          # may have pushed too many commits, and we don't know when to
          # terminate the walk. We thus fall back to using `git rev-list --not
          # --all`, which is a lot less efficient but at least can only ever
          # returns commits which really are new.
          allow_quarantine = false if allow_quarantine && blank_rev?(oldrev)

          newrev
        end.compact

        return [] if newrevs.empty?

        @commits ||= project.repository.new_commits(newrevs, allow_quarantine: allow_quarantine)
      end

      # All commits which have been newly introduced via the given revision.
      def commits_for(oldrev, newrev)
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
          # queued up before. Furthermore, we stop walking as soon as we hit
          # `oldrev` such that we do not include any commits in our checks
          # which have been "over-pushed" by the client.
          commit.parent_ids.each do |parent_id|
            pending.add(parent_id) if commits_by_id.has_key?(parent_id) && parent_id != oldrev
          end

          result << commit
        end

        result
      end

      def single_change_accesses
        @single_changes_accesses ||=
          changes.map do |change|
            commits =
              if blank_rev?(change[:newrev])
                []
              else
                Gitlab::Lazy.new { commits_for(change[:oldrev], change[:newrev]) }
              end

            Checks::SingleChangeAccess.new(
              change,
              user_access: user_access,
              project: project,
              protocol: protocol,
              logger: logger,
              commits: commits
            )
          end
      end

      protected

      def single_access_checks!
        # Iterate over all changes to find if user allowed all of them to be applied
        single_change_accesses.each do |single_change_access|
          single_change_access.validate!
        end
      end

      def bulk_access_checks!
        Gitlab::Checks::LfsCheck.new(self).validate!
      end

      def blank_rev?(rev)
        rev.blank? || Gitlab::Git.blank_ref?(rev)
      end
    end
  end
end

Gitlab::Checks::ChangesAccess.prepend_mod_with('Gitlab::Checks::ChangesAccess')
