# frozen_string_literal: true

class MigrateVSCodeExtensionMarketplaceFeatureFlagToData < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.10'

  def up
    # web_ide_extensions_marketplace was default enabled in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184662
    # no-op
  end

  def down
    # no-op
  end
end
