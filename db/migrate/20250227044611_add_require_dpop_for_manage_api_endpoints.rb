# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddRequireDpopForManageApiEndpoints < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :namespace_settings, :require_dpop_for_manage_api_endpoints, :boolean, null: false, default: true
  end
end
