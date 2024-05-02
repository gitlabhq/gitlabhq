# frozen_string_literal: true

class PrepareAsyncIndexRemovalForVulnerabilities < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  disable_ddl_transaction!

  INDEX_NAME = 'index_vulnerabilities_on_detected_at_and_id'

  # TODO: Index to be destroyed synchronously in follow-up issue in https://gitlab.com/gitlab-org/gitlab/-/issues/458022
  def up
    prepare_async_index_removal :vulnerabilities, [:detected_at, :id], name: INDEX_NAME
  end

  def down
    unprepare_async_index :vulnerabilities, [:detected_at, :id], name: INDEX_NAME
  end
end
