class CreateDnsIpLists < ActiveRecord::Migration
  def change
    create_table :dns_ip_lists do |t|
      t.integer  :user_id
      t.string   :domain
      t.integer  :weight, default: 1
      t.string   :type

      t.timestamps
    end
  end
end
