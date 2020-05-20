# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddLetsencryptErrorsToPagesDomains < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :pages_domains, :auto_ssl_failed, :boolean, default: false # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column :pages_domains, :auto_ssl_failed
  end
end
