# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveColumnDefaultPatOrganization < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.4'

  def change
    change_column_default(:personal_access_tokens, :organization_id, from: 1, to: nil)
  end
end
