# frozen_string_literal: true

class ApplySecurityPoliciesDescriptionTextLimit < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  def up
    add_text_limit :security_policies, :description, 1_000_000
  end

  def down
    remove_text_limit :security_policies, :description
  end
end
