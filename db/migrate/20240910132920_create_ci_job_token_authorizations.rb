# frozen_string_literal: true

class CreateCiJobTokenAuthorizations < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  INDEX_NAME = 'idx_ci_job_token_authorizations_on_accessed_and_origin_project'

  def change
    create_table(:ci_job_token_authorizations, if_not_exists: true) do |t|
      t.bigint :accessed_project_id, null: false
      t.bigint :origin_project_id, null: false, index: true
      t.datetime_with_timezone :last_authorized_at, null: false

      t.index [:accessed_project_id, :origin_project_id], unique: true, name: INDEX_NAME
    end
  end
end
