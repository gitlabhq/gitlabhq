# frozen_string_literal: true

class AddScopeDimensionsToGovernPolicies < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    add_column :govern_policies, :scope_dimensions, :jsonb
  end
end
