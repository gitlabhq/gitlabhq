# frozen_string_literal: true

class AddDependencyProxyTtlGroupPolicyWorkerCapacityToApplicationSettings < Gitlab::Database::Migration[1.0]
  def change
    add_column :application_settings,
               :dependency_proxy_ttl_group_policy_worker_capacity,
               :smallint,
               default: 2,
               null: false
  end
end
