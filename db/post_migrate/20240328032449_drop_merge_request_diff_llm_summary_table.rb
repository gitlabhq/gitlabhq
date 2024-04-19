# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropMergeRequestDiffLlmSummaryTable < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def up
    drop_table :merge_request_diff_llm_summaries
  end

  def down
    create_table :merge_request_diff_llm_summaries do |t|
      t.references :user, null: true, index: true
      t.references :review, null: false, index: true
      t.references :merge_request_diff, null: false
      t.timestamps_with_timezone null: false
      t.integer :provider, null: false, limit: 2
      t.text :content, null: false, limit: 2056
    end
  end
end
