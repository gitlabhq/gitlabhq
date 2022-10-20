# frozen_string_literal: true

class AddMrChecksColumnsToNamespaceSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :namespace_settings, :only_allow_merge_if_pipeline_succeeds, :boolean, default: false, null: false
    add_column :namespace_settings, :allow_merge_on_skipped_pipeline, :boolean, default: false, null: false
    add_column :namespace_settings, :only_allow_merge_if_all_discussions_are_resolved, \
               :boolean, default: false, null: false
  end
end
