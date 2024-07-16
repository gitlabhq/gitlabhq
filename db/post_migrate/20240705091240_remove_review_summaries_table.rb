# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveReviewSummariesTable < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  def up
    drop_table :merge_request_review_llm_summaries, if_exists: true
  end

  def down
    create_table :merge_request_review_llm_summaries, id: :bigserial, force: :cascade do |t|
      t.bigint :user_id
      t.bigint :review_id, null: false
      t.bigint :merge_request_diff_id, null: false
      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
      t.column :provider, :smallint, null: false
      t.text :content, null: false, limit: 2056
      t.integer :cached_markdown_version
      t.text :content_html
      t.bigint :project_id
    end

    add_index :merge_request_review_llm_summaries, :merge_request_diff_id,
      name: :index_merge_request_review_llm_summaries_on_mr_diff_id
    add_index :merge_request_review_llm_summaries, :project_id,
      name: :index_merge_request_review_llm_summaries_on_project_id
    add_index :merge_request_review_llm_summaries, :review_id,
      name: :index_merge_request_review_llm_summaries_on_review_id
    add_index :merge_request_review_llm_summaries, :user_id, name: :index_merge_request_review_llm_summaries_on_user_id

    add_concurrent_foreign_key :merge_request_review_llm_summaries, :reviews, column: :review_id

    install_sharding_key_assignment_trigger(
      table: :merge_request_review_llm_summaries,
      sharding_key: :project_id,
      parent_table: :reviews,
      parent_sharding_key: :project_id,
      foreign_key: :review_id
    )
  end
end
