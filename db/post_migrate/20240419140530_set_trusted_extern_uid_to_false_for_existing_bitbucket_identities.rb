# frozen_string_literal: true

class SetTrustedExternUidToFalseForExistingBitbucketIdentities < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_clusterwide

  milestone '16.11'

  disable_ddl_transaction!

  BATCH_SIZE = 1000

  def up
    define_batchable_model('identities').where(provider: 'bitbucket').each_batch(of: BATCH_SIZE) do |batch|
      batch.update_all(trusted_extern_uid: false)
    end
  end
end
