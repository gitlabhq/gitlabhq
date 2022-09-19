# frozen_string_literal: true

class AddTmpIndexUserCalloutsOnAttentionRequestFeatureNames < Gitlab::Database::Migration[2.0]
  INDEX_NAME = "tmp_index_user_callouts_on_attention_request_feature_names"
  ATTENTION_REQUEST_CALLOUTS = [47, 48]

  disable_ddl_transaction!

  def up
    add_concurrent_index :user_callouts, [:id],
      where: "feature_name IN (#{ATTENTION_REQUEST_CALLOUTS.join(',')})",
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :user_callouts, INDEX_NAME
  end
end
