# frozen_string_literal: true

class AddMarkdownFieldsToReviewLlmSummary < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/AddLimitToTextColumns
    add_column :merge_request_review_llm_summaries,
      :cached_markdown_version,
      :integer,
      null: true
    add_column :merge_request_review_llm_summaries,
      :content_html,
      :text,
      null: true
    # rubocop:enable Migration/AddLimitToTextColumns
  end

  def down
    remove_column :merge_request_review_llm_summaries, :cached_markdown_version
    remove_column :merge_request_review_llm_summaries, :content_html
  end
end
