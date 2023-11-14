# frozen_string_literal: true

class RemoveInProductMarketingEmailsCampaignColumn < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.6'

  TARGET_TABLE = :in_product_marketing_emails
  UNIQUE_INDEX_NAME = :index_in_product_marketing_emails_on_user_campaign
  CONSTRAINT_NAME = :in_product_marketing_emails_track_and_series_or_campaign
  TRACK_AND_SERIES_NOT_NULL_CONSTRAINT = 'track IS NOT NULL AND series IS NOT NULL AND campaign IS NULL'
  CAMPAIGN_NOT_NULL_CONSTRAINT = 'track IS NULL AND series IS NULL AND campaign IS NOT NULL'

  def up
    with_lock_retries do
      remove_column :in_product_marketing_emails, :campaign, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column :in_product_marketing_emails, :campaign, :text, if_not_exists: true
    end

    add_text_limit :in_product_marketing_emails, :campaign, 255

    add_concurrent_index TARGET_TABLE, [:user_id, :campaign], unique: true, name: UNIQUE_INDEX_NAME
    add_check_constraint TARGET_TABLE,
      "(#{TRACK_AND_SERIES_NOT_NULL_CONSTRAINT}) OR (#{CAMPAIGN_NOT_NULL_CONSTRAINT})",
      CONSTRAINT_NAME
  end
end
