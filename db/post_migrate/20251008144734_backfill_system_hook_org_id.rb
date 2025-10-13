# frozen_string_literal: true

class BackfillSystemHookOrgId < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  BATCH_SIZE = 1000

  def up
    organization_id = get_first_organization_id

    return unless organization_id

    web_hooks = define_batchable_model('web_hooks')

    web_hooks
      .where(type: 'SystemHook')
      .where(organization_id: nil)
      .each_batch(of: BATCH_SIZE) do |batch|
      batch.update_all(organization_id: organization_id)
    end
  end

  def down
    # no-op
  end

  private

  def get_first_organization_id
    # Cache the organization ID to avoid repeated queries
    @organization_id ||= connection.select_value(
      "SELECT id FROM organizations ORDER BY id ASC LIMIT 1"
    )
  end
end
