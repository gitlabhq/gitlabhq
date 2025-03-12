# frozen_string_literal: true

class CreateExcludedMergeRequests < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  INDEX_NAME = 'index_excluded_merge_requests_on_merge_request_id'

  def up
    create_table :excluded_merge_requests do |t| # rubocop:disable Migration/EnsureFactoryForTable -- https://gitlab.com/gitlab-org/gitlab/-/issues/517248
      t.references :merge_request, null: false, index: true, foreign_key: { on_delete: :cascade }
    end
  end

  def down
    drop_table :excluded_merge_requests
  end
end
