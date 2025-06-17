# frozen_string_literal: true

class AddOrganizationIdToCiRunnerTaggings < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  TABLE_NAME = 'ci_runner_taggings'

  def up
    add_column TABLE_NAME, :organization_id, :bigint, if_not_exists: true
  end

  def down
    remove_column TABLE_NAME, :organization_id, if_exists: true
  end
end
