# frozen_string_literal: true

class RemoveSecurityPoliciesDescriptionTextLimit < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.7'

  def up
    remove_text_limit :security_policies, :description, constraint_name: 'check_99c8e08928'
  end

  def down
    # no-op: Danger of failing if there are records with length(description) > 255
  end
end
