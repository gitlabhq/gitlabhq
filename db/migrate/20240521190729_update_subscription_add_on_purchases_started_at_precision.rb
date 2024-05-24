# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UpdateSubscriptionAddOnPurchasesStartedAtPrecision < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    change_column :subscription_add_on_purchases, :started_at, :date
  end

  def down
    change_column :subscription_add_on_purchases, :started_at, :datetime_with_timezone
  end
end
