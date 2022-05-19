# frozen_string_literal: true

class AddTextLimitToInProductMarketingEmailCampaign < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_text_limit :in_product_marketing_emails, :campaign, 255
  end

  def down
    remove_text_limit :in_product_marketing_emails, :campaign
  end
end
