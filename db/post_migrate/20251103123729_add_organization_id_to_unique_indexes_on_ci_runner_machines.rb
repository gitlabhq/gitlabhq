# frozen_string_literal: true

class AddOrganizationIdToUniqueIndexesOnCiRunnerMachines < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def up
    # no-op: we don't actually need this index, being removed inside same milestone in
    # 20251111104555_remove_organization_id_from_unique_indexes_on_ci_runner_machines.rb
  end

  def down
    # no-op: we don't actually need this index, being removed inside same milestone in
    # 20251111104555_remove_organization_id_from_unique_indexes_on_ci_runner_machines.rb
  end
end
