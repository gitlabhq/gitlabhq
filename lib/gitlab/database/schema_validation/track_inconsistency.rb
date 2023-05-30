# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      class TrackInconsistency
        COLUMN_TEXT_LIMIT = 6144

        def initialize(inconsistency, project, user)
          @inconsistency = inconsistency
          @project = project
          @user = user
        end

        def execute
          return unless Gitlab.com?
          return refresh_issue if inconsistency_record.present?

          result = ::Issues::CreateService.new(container: project, current_user: user, params: params,
            spam_params: nil).execute

          track_inconsistency(result[:issue]) if result.success?
        end

        private

        attr_reader :inconsistency, :project, :user

        def track_inconsistency(issue)
          schema_inconsistency_model.create!(
            issue: issue,
            object_name: inconsistency.object_name,
            table_name: inconsistency.table_name,
            valitador_name: inconsistency.type,
            diff: inconsistency_diff
          )
        end

        def params
          {
            title: issue_title,
            description: description,
            issue_type: 'issue',
            labels: %w[database database-inconsistency-report]
          }
        end

        def issue_title
          "New schema inconsistency: #{inconsistency.object_name}"
        end

        def description
          <<~MSG
            We have detected a new schema inconsistency.

            **Table name:** #{inconsistency.table_name}\
            **Object name:** #{inconsistency.object_name}\
            **Validator name:** #{inconsistency.type}\
            **Object type:** #{inconsistency.object_type}\
            **Error message:** #{inconsistency.error_message}


            **Structure.sql statement:**

            ```sql
            #{inconsistency.structure_sql_statement}
            ```

            **Database statement:**

            ```sql
            #{inconsistency.database_statement}
            ```

            **Diff:**

            ```diff
            #{inconsistency.diff}

            ```


            For more information, please contact the database team.
          MSG
        end

        def schema_inconsistency_model
          Gitlab::Database::SchemaValidation::SchemaInconsistency
        end

        def refresh_issue
          return if inconsistency_diff == inconsistency_record.diff # Nothing to refresh

          note = ::Notes::CreateService.new(
            inconsistency_record.issue.project,
            user,
            { noteable_type: 'Issue', noteable: inconsistency_record.issue, note: description }
          ).execute

          inconsistency_record.update!(diff: inconsistency_diff) if note.persisted?
        end

        def inconsistency_diff
          @inconsistency_diff ||= inconsistency.diff.to_s.first(COLUMN_TEXT_LIMIT)
        end

        def inconsistency_record
          @inconsistency_record ||= schema_inconsistency_model.with_open_issues.find_by(
            object_name: inconsistency.object_name,
            table_name: inconsistency.table_name,
            valitador_name: inconsistency.type
          )
        end
      end
    end
  end
end
