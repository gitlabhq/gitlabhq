# frozen_string_literal: true

module SystemCheck
  module App
    class TableTruncateCheck < SystemCheck::BaseCheck
      set_name 'Tables are truncated?'

      def skip?
        Gitlab::Database.database_mode != Gitlab::Database::MODE_MULTIPLE_DATABASES
      end

      def check?
        @rake_tasks = []
        Gitlab::Database.database_base_models_with_gitlab_shared.keys.each_with_object({}) do |database_name, _h|
          if Gitlab::Database::TablesTruncate.new(database_name: database_name).needs_truncation?
            @rake_tasks << "gitlab:db:truncate_legacy_tables:#{database_name}"
          end
        end

        @rake_tasks.empty?
      end

      def show_error
        try_fixing_it(
          sudo_gitlab("bundle exec rake #{@rake_tasks.join(' ')}")
        )
        for_more_information(
          "doc/development/database/multiple_databases.md in section 'Truncating tables'"
        )
        fix_and_rerun
      end
    end
  end
end
