# frozen_string_literal: true
class CleanupAttentionRequestUserCallouts < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  ATTENTION_REQUEST_CALLOUTS = [47, 48]
  # 47 and 48 were removed with https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95446

  def up
    define_batchable_model('user_callouts')
      .where(feature_name: ATTENTION_REQUEST_CALLOUTS)
      .each_batch { |batch| batch.delete_all } # rubocop:disable Style/SymbolProc
  end

  def down
    # Attention request feature has been reverted.
  end
end
