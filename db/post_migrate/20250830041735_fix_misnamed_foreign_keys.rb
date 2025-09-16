# frozen_string_literal: true

class FixMisnamedForeignKeys < Gitlab::Database::Migration[2.3]
  include ::Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.4'

  FOREIGN_KEYS = [
    {
      table: 'packages_tags',
      # Original table name: packages_package_tags
      # OpenSSL::Digest::SHA256.hexdigest("packages_package_tags_package_id_fk")
      old_name: 'fk_rails_2b18ae9256',
      new_name: 'fk_rails_1dfc868911'
    },
    {
      table: 'pool_repositories',
      # Original table name: repositories
      # OpenSSL::Digest::SHA256.hexdigest("repositories_shard_id_fk")
      old_name: 'fk_rails_95a99c2d56',
      new_name: 'fk_rails_af3f8c5d62'
    },
    {
      table: 'design_management_designs_versions',
      old_name: 'fk_03c671965c',
      new_name: 'fk_rails_03c671965c'
    },
    {
      table: 'design_management_designs_versions',
      old_name: 'fk_f4d25ba00c',
      new_name: 'fk_rails_f4d25ba00c'
    },
    {
      table: 'todos',
      old_name: 'fk_a27c483435',
      new_name: 'fk_rails_a27c483435'
    },
    {
      table: 'boards',
      old_name: 'fk_1e9a074a35',
      new_name: 'fk_rails_1e9a074a35'
    },
    {
      table: 'remote_mirrors',
      old_name: 'fk_43a9aa4ca8',
      new_name: 'fk_rails_43a9aa4ca8'
    },
    {
      table: 'events',
      old_name: 'fk_61fbf6ca48',
      new_name: 'fk_rails_61fbf6ca48'
    },
    {
      table: 'project_mirror_data',
      old_name: 'fk_d1aad367d7',
      new_name: 'fk_rails_d1aad367d7'
    },
    {
      table: 'security_policies',
      old_name: 'fk_08722e8ac7',
      new_name: 'fk_rails_08722e8ac7'
    },
    {
      table: 'dependency_proxy_group_settings',
      old_name: 'fk_616ddd680a',
      new_name: 'fk_rails_616ddd680a'
    },
    {
      table: 'jira_connect_subscriptions',
      old_name: 'fk_a3c10bcf7d',
      new_name: 'fk_rails_a3c10bcf7d'
    },
    {
      table: 'dependency_proxy_blobs',
      old_name: 'fk_db58bbc5d7',
      new_name: 'fk_rails_db58bbc5d7'
    },
    {
      table: 'approval_policy_rules',
      old_name: 'fk_e344cb2d35',
      new_name: 'fk_rails_e344cb2d35'
    },
    {
      table: 'jira_connect_subscriptions',
      old_name: 'fk_f1d617343f',
      new_name: 'fk_rails_f1d617343f'
    }
  ].freeze

  def up
    FOREIGN_KEYS.each do |data|
      table = data[:table]
      old_name = data[:old_name]
      new_name = data[:new_name]

      next unless foreign_key_exists?(table, name: old_name)
      next if foreign_key_exists?(table, name: new_name)

      with_lock_retries do
        rename_constraint(table, old_name, new_name)
      end
    end
  end

  def down; end
end
