class AddSecondaryExternUidToIdentities < ActiveRecord::Migration
  def change
    add_column :identities, :secondary_extern_uid, :string
  end
end
