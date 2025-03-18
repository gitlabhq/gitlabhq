# frozen_string_literal: true

class AddPoliciesColumnToCiJobTokenAuthorizations < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :ci_job_token_authorizations, :job_token_policies, :jsonb, default: {}, null: false
  end
end
