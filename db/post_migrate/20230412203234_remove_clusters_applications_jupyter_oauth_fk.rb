# frozen_string_literal: true

class RemoveClustersApplicationsJupyterOauthFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:clusters_applications_jupyter, column: :oauth_application_id)
    end
  end

  def down
    add_concurrent_foreign_key :clusters_applications_jupyter, :oauth_applications,
      column: :oauth_application_id, on_delete: :nullify, name: 'fk_rails_331f0aff78'
  end
end
