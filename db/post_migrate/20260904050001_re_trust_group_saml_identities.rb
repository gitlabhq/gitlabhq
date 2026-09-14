# frozen_string_literal: true

class ReTrustGroupSamlIdentities < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_user

  BATCH_SIZE = 1000

  # NULL is not re-trusted because the PATCH /groups/:id/saml/:uid endpoint
  # only ever set the flag to false.
  def up
    define_batchable_model('identities').where(provider: 'group_saml').each_batch(of: BATCH_SIZE) do |batch|
      batch.where(trusted_extern_uid: false).update_all(trusted_extern_uid: true)
    end
  end

  def down
    # no-op
    #
    # Once trust is restored there is no way to tell which rows were previously
    # untrusted, so this cannot be reversed.
  end
end
