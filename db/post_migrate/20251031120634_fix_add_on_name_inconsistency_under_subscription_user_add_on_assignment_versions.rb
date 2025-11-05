# frozen_string_literal: true

class FixAddOnNameInconsistencyUnderSubscriptionUserAddOnAssignmentVersions < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # Update numeric add_on_name values to their string equivalents
    # Mapping based on GitlabSubscriptions::AddOn enum:
    # 1 => code_suggestions, 2 => product_analytics, 3 => duo_enterprise
    # 4 => duo_amazon_q, 5 => duo_core, 6 => duo_self_hosted

    # Use a single table scan with CASE statement to avoid multiple loops
    define_batchable_model(:subscription_user_add_on_assignment_versions)
      .each_batch(of: 500) do |batch|
        batch.where(add_on_name: %w[1 2 3 4 5 6]).update_all(<<~SQL.squish)
          add_on_name = CASE add_on_name
            WHEN '1' THEN 'code_suggestions'
            WHEN '2' THEN 'product_analytics'
            WHEN '3' THEN 'duo_enterprise'
            WHEN '4' THEN 'duo_amazon_q'
            WHEN '5' THEN 'duo_core'
            WHEN '6' THEN 'duo_self_hosted'
            ELSE add_on_name
          END
        SQL
      end
  end

  def down
    # no-op
  end
end
