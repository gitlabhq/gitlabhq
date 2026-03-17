# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      # Helper module for background migrations that rename assignable permissions
      # in the `granular_scopes` table.
      #
      # Usage: include this module in a batched background migration class.
      # See: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#renaming-assignable-permissions
      module GranularScopePermissions
        extend ActiveSupport::Concern

        included do
          delegate :execute, to: :connection

          cursor :id
          job_arguments :old_permission, :new_permissions

          operation_name :rename_granular_scope_permission
        end

        def perform
          each_sub_batch(
            batching_scope: scope_with_permission(old_permission)
          ) do |sub_batch|
            rename_granular_scope_permission(old_permission, new_permissions,
              batch_scope: sub_batch.select(:id).to_sql)
          end
        end

        private

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

        def scope_with_permission(permission)
          ->(relation) { relation.where("permissions @> #{contains_permission_sql(permission)}") }
        end

        def contains_permission_sql(permission)
          "#{connection.quote(permission.to_json)}::jsonb"
        end
      end
    end
  end
end
