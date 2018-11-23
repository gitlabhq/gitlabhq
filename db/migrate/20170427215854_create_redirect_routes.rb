# rubocop:disable Migration/Timestamps
class CreateRedirectRoutes < ActiveRecord::Migration[4.2]
  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    create_table :redirect_routes do |t|
      t.integer :source_id, null: false
      t.string :source_type, null: false
      t.string :path, null: false

      t.timestamps null: false
    end
  end
end
