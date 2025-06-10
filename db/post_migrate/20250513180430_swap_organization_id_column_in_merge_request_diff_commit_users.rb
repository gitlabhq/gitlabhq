# frozen_string_literal: true

class SwapOrganizationIdColumnInMergeRequestDiffCommitUsers < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  TABLE_NAME = :merge_request_diff_commit_users

  def up
    # This column is not used at all yet and can be dropped easily. It's null for all rows.

    # rubocop:disable Migration/SchemaAdditionMethodsNoPost -- It's a temporary column that will be immediately renamed
    add_column TABLE_NAME, :organization_id_tmp, :bigint, default: 1, null: false
    # rubocop:enable Migration/SchemaAdditionMethodsNoPost

    remove_column TABLE_NAME, :organization_id
    rename_column TABLE_NAME, :organization_id_tmp, :organization_id
  end

  def down
    # Remove the newly set default and not null constraint
    add_column TABLE_NAME, :organization_id_tmp, :bigint
    remove_column TABLE_NAME, :organization_id
    rename_column TABLE_NAME, :organization_id_tmp, :organization_id
  end
end
