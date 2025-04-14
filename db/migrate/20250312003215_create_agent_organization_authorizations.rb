# frozen_string_literal: true

class CreateAgentOrganizationAuthorizations < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    create_table :agent_organization_authorizations do |t| # rubocop:disable Migration/EnsureFactoryForTable -- factory is agent_ci_access_organization_authorization
      t.bigint :organization_id, null: false, index: true
      t.references :agent, null: false, index: { unique: true },
        foreign_key: { to_table: :cluster_agents, on_delete: :cascade }
      t.jsonb :config, null: false
    end
  end
end
