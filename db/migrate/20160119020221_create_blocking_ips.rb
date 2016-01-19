class CreateBlockingIps < ActiveRecord::Migration
  def change
    create_table :blocking_ips do |t|
      t.integer :user_id
      t.string  :ip
      t.text    :description
      t.string  :type

      t.timestamps
    end
  end
end
