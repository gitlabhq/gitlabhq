# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class is used to update the default_branch_protection_defaults column
    # for user namespaces of the namespace_settings table.
    class BackfillDefaultBranchProtectionNamespaceSetting < BatchedMigrationJob
      operation_name :set_default_branch_protection_defaults
      feature_category :database

      # Migration only version of `namespaces` table
      class Namespace < ::ApplicationRecord
        self.table_name = 'namespaces'
        self.inheritance_column = :_type_disabled

        has_one :namespace_setting,
          class_name: '::Gitlab::BackgroundMigration::BackfillDefaultBranchProtectionNamespaceSetting::NamespaceSetting'
      end

      # Migration only version of `namespace_settings` table
      class NamespaceSetting < ::ApplicationRecord
        self.table_name = 'namespace_settings'
        belongs_to :namespace,
          class_name: '::Gitlab::BackgroundMigration::BackfillDefaultBranchProtectionNamespaceSetting::Namespace'
      end

      # Migration only version of Gitlab::Access:BranchProtection application code.
      class BranchProtection
        attr_reader :level

        def initialize(level)
          @level = level
        end

        PROTECTION_NONE = 0
        PROTECTION_DEV_CAN_PUSH = 1
        PROTECTION_FULL = 2
        PROTECTION_DEV_CAN_MERGE = 3
        PROTECTION_DEV_CAN_INITIAL_PUSH = 4

        DEVELOPER = 30
        MAINTAINER = 40

        def to_hash
          case level
          when PROTECTION_NONE
            self.class.protection_none
          when PROTECTION_DEV_CAN_PUSH
            self.class.protection_partial
          when PROTECTION_FULL
            self.class.protected_fully
          when PROTECTION_DEV_CAN_MERGE
            self.class.protected_against_developer_pushes
          when PROTECTION_DEV_CAN_INITIAL_PUSH
            self.class.protected_after_initial_push
          end
        end

        class << self
          def protection_none
            {
              allowed_to_push: [{ 'access_level' => DEVELOPER }],
              allowed_to_merge: [{ 'access_level' => DEVELOPER }],
              allow_force_push: true
            }
          end

          def protection_partial
            protection_none.merge(allow_force_push: false)
          end

          def protected_fully
            {
              allowed_to_push: [{ 'access_level' => MAINTAINER }],
              allowed_to_merge: [{ 'access_level' => MAINTAINER }],
              allow_force_push: false
            }
          end

          def protected_against_developer_pushes
            {
              allowed_to_push: [{ 'access_level' => MAINTAINER }],
              allowed_to_merge: [{ 'access_level' => DEVELOPER }],
              allow_force_push: true
            }
          end

          def protected_after_initial_push
            {
              allowed_to_push: [{ 'access_level' => MAINTAINER }],
              allowed_to_merge: [{ 'access_level' => DEVELOPER }],
              allow_force_push: true,
              developer_can_initial_push: true
            }
          end
        end
      end

      def perform
        each_sub_batch do |sub_batch|
          update_default_protection_branch_defaults(sub_batch)
        end
      end

      private

      def update_default_protection_branch_defaults(batch)
        namespace_settings = NamespaceSetting.where(namespace_id: batch.pluck(:namespace_id)).includes(:namespace)

        values_list = namespace_settings.map do |namespace_setting|
          level = namespace_setting.namespace.default_branch_protection.to_i
          value = BranchProtection.new(level).to_hash.to_json
          "(#{namespace_setting.namespace_id}, '#{value}'::jsonb)"
        end.join(", ")

        sql = <<~SQL
          WITH new_values (namespace_id, default_branch_protection_defaults) AS (
            VALUES
              #{values_list}
          )
          UPDATE namespace_settings
          SET default_branch_protection_defaults = new_values.default_branch_protection_defaults
          FROM new_values
          WHERE namespace_settings.namespace_id = new_values.namespace_id;
        SQL

        connection.execute(sql)
      end
    end
  end
end
