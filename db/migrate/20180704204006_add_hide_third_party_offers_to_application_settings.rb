class AddHideThirdPartyOffersToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, :hide_third_party_offers,
                            :boolean,
                            default: false,
                            allow_null: false)
  end

  def down
    remove_column(:application_settings, :hide_third_party_offers)
  end
end
