# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Strips leading/trailing whitespace from `members.invite_email` for rows that
    # currently fail email validation *only* because of the surrounding whitespace.
    #
    # A row is updated when, and only when, the stripped value:
    #   - differs from the stored value (there is whitespace to strip), and
    #   - is a valid email once stripped.
    #
    # Rows whose stripped value would still be invalid are left untouched, so this
    # is purely a cleanup of stale metadata and never changes an access grant.
    class StripWhitespaceFromMembersInviteEmail < BatchedMigrationJob
      operation_name :strip_whitespace_from_members_invite_email
      feature_category :groups_and_projects

      # Copied from Devise.email_regexp (the default DeviseEmailValidator uses) and its
      # encoded-word rejection. Copied inline rather than referenced so the job stays
      # forward-compatible: it is enqueued now but runs later, across versions/instances.
      EMAIL_REGEXP = /\A[^@\s]+@[^@\s]+\z/
      ENCODED_WORD_REGEXP = /=[?].*[?]=/

      # Filtering happens in Ruby rather than via `scope_to` with a DB pre-filter.
      # We strip all String#strip whitespace (tabs, newlines, etc.), not just ASCII
      # spaces, so a `LIKE ' %' OR LIKE '% '` scope would silently skip tab/newline
      # rows. A correct `invite_email ~ '(^\s)|(\s$)'` regex can't use an index on
      # invite_email either, so it wouldn't avoid the per-batch scan. This is a
      # one-time cleanup over a small matching set, so the Ruby filter is preferred.
      def perform
        each_sub_batch do |sub_batch|
          updates = sub_batch
            .where.not(invite_email: nil)
            .pluck(:id, :invite_email)
            .filter_map do |id, email|
              stripped = email.strip
              next if stripped == email
              next unless EMAIL_REGEXP.match?(stripped) && !ENCODED_WORD_REGEXP.match?(stripped)

              [id, stripped]
            end

          updates.each do |id, stripped|
            sub_batch.klass.where(id: id).update_all(invite_email: stripped)
          end
        end
      end
    end
  end
end
