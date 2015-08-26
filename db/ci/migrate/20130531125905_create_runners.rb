class CreateRunners < ActiveRecord::Migration
  def change
    create_table :runners do |t|
      t.string :token
      t.text :public_key

      t.timestamps
    end
  end
end
