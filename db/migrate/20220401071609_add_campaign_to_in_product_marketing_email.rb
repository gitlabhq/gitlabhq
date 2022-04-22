# frozen_string_literal: true

class AddCampaignToInProductMarketingEmail < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  TARGET_TABLE = :in_product_marketing_emails
  UNIQUE_INDEX_NAME = :index_in_product_marketing_emails_on_user_campaign
  CONSTRAINT_NAME = :in_product_marketing_emails_track_and_series_or_campaign
  TRACK_AND_SERIES_NOT_NULL_CONSTRAINT = 'track IS NOT NULL AND series IS NOT NULL AND campaign IS NULL'
  CAMPAIGN_NOT_NULL_CONSTRAINT = 'track IS NULL AND series IS NULL AND campaign IS NOT NULL'

  def up
    change_column_null TARGET_TABLE, :track, true
    change_column_null TARGET_TABLE, :series, true

    # rubocop:disable Migration/AddLimitToTextColumns
    # limit is added in 20220420034519_add_text_limit_to_in_product_marketing_email_campaign.rb
    add_column :in_product_marketing_emails, :campaign, :text, if_not_exists: true
    # rubocop:enable Migration/AddLimitToTextColumns
    add_concurrent_index TARGET_TABLE, [:user_id, :campaign], unique: true, name: UNIQUE_INDEX_NAME
    add_check_constraint TARGET_TABLE,
      "(#{TRACK_AND_SERIES_NOT_NULL_CONSTRAINT}) OR (#{CAMPAIGN_NOT_NULL_CONSTRAINT})",
      CONSTRAINT_NAME
  end

  def down
    remove_check_constraint TARGET_TABLE, CONSTRAINT_NAME
    remove_concurrent_index TARGET_TABLE, [:user_id, :campaign], name: UNIQUE_INDEX_NAME
    remove_column :in_product_marketing_emails, :campaign, if_exists: true

    # Records that previously had a value for campaign column will have NULL
    # values for track and series columns so we can't reverse
    # change_column_null.
  end
end
