# frozen_string_literal: true

class ClearDomainEntriesFromIframeRenderingAllowlist < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute 'UPDATE application_settings SET iframe_rendering_allowlist = NULL'
  end

  def down
    # Can't restore old setting (data removed); only for `type: wip` FF, no active users.
  end
end
