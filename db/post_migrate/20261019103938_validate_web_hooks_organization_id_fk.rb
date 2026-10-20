# frozen_string_literal: true

class ValidateWebHooksOrganizationIdFk < Gitlab::Database::Migration[2.3]
  milestone '19.6'

  def up
    validate_foreign_key :web_hooks, :organization_id, name: :fk_e295b26646
  end

  def down
    # no-op
  end
end
