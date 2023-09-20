# frozen_string_literal: true

class IndexFindingIdForVulnerabilities < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_vulnerabilities_on_finding_id'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/423541
  def up
    prepare_async_index :vulnerabilities, :finding_id, name: INDEX_NAME
  end

  def down
    unprepare_async_index :vulnerabilities, INDEX_NAME
  end
end
