# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddKubernetesVersionToClusterProvidersAws < ActiveRecord::Migration[6.0]
  # Uncomment the following include if you require helper functions:
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless column_exists?(:cluster_providers_aws, :kubernetes_version)
      add_column :cluster_providers_aws, :kubernetes_version, :text, null: false, default: '1.14'
    end

    add_text_limit :cluster_providers_aws, :kubernetes_version, 30
  end

  def down
    if column_exists?(:cluster_providers_aws, :kubernetes_version)
      remove_column :cluster_providers_aws, :kubernetes_version
    end
  end
end
