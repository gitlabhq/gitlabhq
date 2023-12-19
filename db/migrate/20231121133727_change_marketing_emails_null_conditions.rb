# frozen_string_literal: true

class ChangeMarketingEmailsNullConditions < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.7'

  def up
    add_not_null_constraint :in_product_marketing_emails, :track
    add_not_null_constraint :in_product_marketing_emails, :series
  end

  def down
    remove_not_null_constraint :in_product_marketing_emails, :track
    remove_not_null_constraint :in_product_marketing_emails, :series
  end
end
