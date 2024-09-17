# frozen_string_literal: true

class CreateClusterAgentUrlConfigurations < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    create_table :cluster_agent_url_configurations do |t| # rubocop:disable Migration/EnsureFactoryForTable -- https://gitlab.com/gitlab-org/gitlab/-/issues/468630
      t.timestamps_with_timezone null: false
      t.bigint :agent_id, null: false
      t.bigint :project_id, null: false
      t.bigint :created_by_user_id
      t.integer :status, limit: 2, null: false, default: 0
      t.text :url, limit: 2.kilobytes, null: false
      t.text :ca_cert, limit: 16.kilobytes
      t.text :client_key, limit: 16.kilobytes
      t.text :client_cert, limit: 16.kilobytes
      t.text :tls_host, limit: 2.kilobytes
      t.binary :public_key
      t.binary :encrypted_private_key
      t.binary :encrypted_private_key_iv

      t.index :agent_id
      t.index :project_id
      t.index :created_by_user_id, where: 'created_by_user_id IS NOT NULL',
        name: 'index_cluster_agent_url_configurations_on_user_id'
    end
  end
end
