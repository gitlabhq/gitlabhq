# frozen_string_literal: true

class ChangeSubscriptionAddOnPurchasesOrganizationIdDefault < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  DEFAULT_ORGANIZATION_ID = 1

  def up
    change_column_default('subscription_add_on_purchases', 'organization_id', nil)
  end

  def down
    change_column_default('subscription_add_on_purchases', 'organization_id', DEFAULT_ORGANIZATION_ID)
  end
end
