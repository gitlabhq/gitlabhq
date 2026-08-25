# frozen_string_literal: true

require_relative '../../rubocop/formatter/graceful_formatter'

module Keeps
  module Helpers
    # Removes the RuboCop grace period line (`Details: grace period`) from `.rubocop_todo` YAML files, but only once
    # the grace period is at least MIN_AGE_DAYS old.
    #
    # A grace period is considered overdue when it was already present in the file at the revision from MIN_AGE_DAYS
    # ago. We check the grace period line itself, not just the file, because RuboCop re-adds it to an existing todo
    # file whenever its Exclude list grows, which starts a fresh grace period. This works under the treeless, shallow
    # clone (`--filter=tree:0`) used in CI: it reads the commit list (fully fetched) and only one historical tree,
    # instead of walking the whole file history.
    #
    # See https://docs.gitlab.com/development/rubocop_development_guide/#cop-grace-period.
    class RubocopGracePeriodRemover
      TODO_DIR_PATTERN = ".rubocop_todo/*.yml"
      KEY_VALUE = ::RuboCop::Formatter::GracefulFormatter.grace_period_key_value.freeze
      MIN_AGE_DAYS = 7
      PATTERN = /^[ \t]*#{Regexp.escape(KEY_VALUE)}\n/

      def remove_overdue
        files_with_grace_period.each do |file|
          next unless overdue?(file)

          remove_grace_period(file)
        end
      end

      private

      # Use `git grep` to find the few files containing a grace period in a single pass instead of scanning every todo
      # file in Ruby.
      def files_with_grace_period
        output = ::Gitlab::Housekeeper::Shell.execute(
          'git', 'grep', '--files-with-matches', '--fixed-strings', KEY_VALUE, '--', TODO_DIR_PATTERN
        )

        output.each_line.map(&:chomp).reject(&:empty?)
      rescue ::Gitlab::Housekeeper::Shell::Error => e
        # `git grep` exits non-zero when there are no matches, which is expected.
        warn "[RubocopGracePeriodRemover] git grep found no files with a grace period: #{e.message}"
        []
      end

      def remove_grace_period(file_path)
        content = File.read(file_path)
        File.write(file_path, content.gsub(PATTERN, ''))
      end

      # A grace period is overdue when it was already present in the file at the revision from MIN_AGE_DAYS ago.
      # Checking the grace period line (rather than just the file) ensures one that a regeneration run just re-added,
      # because the Exclude list grew, is not stripped again in the same pass.
      def overdue?(file_path)
        return false unless cutoff_revision

        grace_period_present_at?(cutoff_revision, file_path)
      end

      # The cutoff revision depends only on the current time, so compute it once per run and reuse it across files.
      def cutoff_revision
        return @cutoff_revision if defined?(@cutoff_revision)

        @cutoff_revision = revision_before(MIN_AGE_DAYS.days.ago)
      end

      def revision_before(time)
        output = ::Gitlab::Housekeeper::Shell.execute(
          'git', 'rev-list', '--max-count=1', "--before=#{time.utc.iso8601}", 'HEAD'
        )

        revision = output.strip
        revision.empty? ? nil : revision
      rescue ::Gitlab::Housekeeper::Shell::Error => e
        warn "[RubocopGracePeriodRemover] git rev-list failed: #{e.message}"
        nil
      end

      def grace_period_present_at?(revision, file_path)
        ::Gitlab::Housekeeper::Shell.execute(
          'git', 'grep', '--quiet', '--fixed-strings', KEY_VALUE, revision, '--', file_path
        )
        true
      rescue ::Gitlab::Housekeeper::Shell::Error => e
        # `git grep --quiet` exits non-zero when the grace period is absent at that revision (the expected case), but
        # also on a genuine failure such as a missing revision, so log it and treat the grace period as absent.
        warn "[RubocopGracePeriodRemover] git grep at #{revision} for #{file_path}: #{e.message}"
        false
      end
    end
  end
end
