# frozen_string_literal: true

class CreateProjectAuthorizationReverifications < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  USER_INDEX_NAME = 'idx_project_authz_reverifications_on_user_id'
  ENQUEUED_INDEX_NAME = 'idx_project_authz_reverifications_on_enqueued_at'
  REFRESH_STARTED_INDEX_NAME = 'idx_project_authz_reverifications_on_refresh_started_at'

  def change
    create_table :project_authorization_reverifications do |t|
      t.references :user,
        index: { unique: true, name: USER_INDEX_NAME },
        null: false
      t.datetime_with_timezone :enqueued_at, null: false
      t.datetime_with_timezone :refresh_started_at
      t.integer :status, limit: 2, null: false, default: 0

      t.index :enqueued_at, where: 'status IN (0, 2)', name: ENQUEUED_INDEX_NAME
      t.index :refresh_started_at, where: 'status = 1', name: REFRESH_STARTED_INDEX_NAME
    end
  end
end
