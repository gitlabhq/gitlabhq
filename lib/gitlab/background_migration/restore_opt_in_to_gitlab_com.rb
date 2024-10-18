# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class RestoreOptInToGitlabCom < BatchedMigrationJob
      job_arguments :temporary_table_name
      operation_name :update
      feature_category :activation

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.connection.execute(
            construct_query(
              sub_batch
                .where.not('onboarding_status::jsonb ? :key', key: 'email_opt_in')
                .joins("INNER JOIN #{temporary_table_name} on user_id = #{temporary_table_name}.GITLAB_DOTCOM_ID")
            )
          )
        end
      end

      private

      def construct_query(sub_batch)
        <<~SQL
          UPDATE #{batch_table}
          SET onboarding_status = jsonb_set(
            #{batch_table}.onboarding_status, '{email_opt_in}', to_jsonb(#{temporary_table_name}.RESTORE_VALUE)
          )
          FROM #{temporary_table_name}
          WHERE #{temporary_table_name}.GITLAB_DOTCOM_ID = #{batch_table}.user_id
          AND #{temporary_table_name}.RESTORE_VALUE IS NOT NULL
          AND #{batch_table}.user_id IN (#{sub_batch.select(:user_id).to_sql})
        SQL
      end
    end
  end
end
