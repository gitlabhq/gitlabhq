# frozen_string_literal: true

class DeleteBitbucketIdentitiesWithUntrustedExternUid < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_clusterwide

  milestone '17.1'

  BATCH_SIZE = 1000

  def up
    define_batchable_model('identities').where(provider: 'bitbucket').each_batch(of: BATCH_SIZE) do |batch|
      batch.where(trusted_extern_uid: false).delete_all
    end
  end
end
