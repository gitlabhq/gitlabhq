# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDefaultBranchProtectionSettings < BatchedMigrationJob
      operation_name :set_default_branch_protection_settings
      feature_category :source_code_management

      def perform
        each_sub_batch do |sub_batch|
          update_default_protection_branch_defaults(sub_batch)
        end
      end

      private

      def update_default_protection_branch_defaults(batch)
        namespace_ids = batch.pluck(:id)

        return if namespace_ids.blank?

        sql =  <<-SQL
          UPDATE namespace_settings
          SET default_branch_protection_defaults = '{}'
          FROM namespaces
          WHERE namespace_settings.namespace_id = namespaces.id
            AND namespaces.id IN (#{namespace_ids.join(', ')})
            AND namespaces.default_branch_protection IS NULL
            AND namespace_settings.default_branch_protection_defaults @> '#{protection_none}'::jsonb
        SQL

        connection.execute(sql)
      end

      def protection_none
        {
          "allowed_to_push" => [{ "access_level" => 30 }],
          "allowed_to_merge" => [{ "access_level" => 30 }],
          "allow_force_push" => true
        }.to_json
      end
    end
  end
end
