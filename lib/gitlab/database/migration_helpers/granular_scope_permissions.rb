# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      # Helper module for background migrations that rename assignable permissions
      # in the `granular_scopes` table. Including classes must define a `RENAMES`
      # constant mapping old permission names to new ones:
      #
      #    class RenameManyPermissions < BatchedMigrationJob
      #      RENAMES = {
      #        'old_name' => 'new_name',
      #        'split_me' => %w[part_a part_b]
      #      }.freeze
      #
      #      include Gitlab::Database::MigrationHelpers::GranularScopePermissions
      #
      #      feature_category :permissions
      #    end
      #
      # See: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#renaming-assignable-permissions
      module GranularScopePermissions
        extend ActiveSupport::Concern

        included do
          delegate :execute, to: :connection

          cursor :id
          operation_name :rename_granular_scope_permission
        end

        def perform
          perform_renames(self.class::RENAMES)
        end

        private

        def perform_renames(renames)
          each_sub_batch(
            batching_scope: scope_with_any_permission(renames.keys)
          ) do |sub_batch|
            batch_sql = sub_batch.select(:id).to_sql

            renames.each do |old_name, new_names|
              rename_granular_scope_permission(old_name, new_names,
                batch_scope: batch_sql)
            end
          end
        end

        def rename_granular_scope_permission(old_permission, new_permissions, batch_scope:)
          new_permissions = Array(new_permissions)
          new_jsonb = connection.quote(new_permissions.to_json)
          old_quoted = connection.quote(old_permission)
          contains_old = contains_permission_sql(old_permission)

          execute <<~SQL
            UPDATE granular_scopes
            SET permissions = (
              SELECT jsonb_agg(DISTINCT elem)
              FROM jsonb_array_elements(
                (permissions - #{old_quoted}) || #{new_jsonb}::jsonb
              ) AS elem
            )
            WHERE id IN (#{batch_scope}) AND permissions @> #{contains_old}
          SQL
        end

        def scope_with_any_permission(permissions)
          ->(relation) { relation.where('permissions ?| array[:keys]', keys: permissions) }
        end

        def contains_permission_sql(permission)
          "#{connection.quote(permission.to_json)}::jsonb"
        end
      end
    end
  end
end
