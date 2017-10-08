# rubocop:disable all
class CreateSubscriptionsTable < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    create_table :subscriptions do |t|
      t.integer :user_id
      t.references :subscribable, polymorphic: true
      t.boolean :subscribed

      t.timestamps null: true
    end

    add_index :subscriptions,
              [:subscribable_id, :subscribable_type, :user_id],
              unique: true,
              name: 'subscriptions_user_id_and_ref_fields'
  end
end
