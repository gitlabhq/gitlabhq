# frozen_string_literal: true

class AddMrRequiresSamlAuthForApprovalToGroupMrApprovalSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column(
      :group_merge_request_approval_settings,
      :require_saml_auth_to_approve,
      :boolean,
      default: false,
      null: false
    )
  end
end
