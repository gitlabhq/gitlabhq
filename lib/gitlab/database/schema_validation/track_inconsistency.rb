# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      class TrackInconsistency
        def initialize(inconsistency, project, user)
          @inconsistency = inconsistency
          @project = project
          @user = user
        end

        def execute
          return unless Gitlab.com?
          return if inconsistency_record.present?

          result = ::Issues::CreateService.new(container: project, current_user: user, params: params,
            spam_params: nil).execute

          track_inconsistency(result[:issue]) if result.success?
        end

        private

        attr_reader :inconsistency, :project, :user

        def track_inconsistency(issue)
          schema_inconsistency_model.create(
            issue: issue,
            object_name: inconsistency.object_name,
            table_name: inconsistency.table_name,
            valitador_name: inconsistency.type
          )
        end

        def params
          {
            title: issue_title,
            description: issue_description,
            issue_type: 'issue',
            labels: %w[database database-inconsistency-report]
          }
        end

        def issue_title
          "New schema inconsistency: #{inconsistency.object_name}"
        end

        def issue_description
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

        def inconsistency_record
          schema_inconsistency_model.find_by(
            object_name: inconsistency.object_name,
            table_name: inconsistency.table_name,
            valitador_name: inconsistency.type
          )
        end
      end
    end
  end
end
