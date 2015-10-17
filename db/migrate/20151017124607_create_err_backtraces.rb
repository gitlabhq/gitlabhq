class CreateErrBacktraces < ActiveRecord::Migration
  def change
    create_table :err_backtraces do |t|
      t.belongs_to :err, index: true
      t.string :method
      t.string :file
      t.integer :line
      t.integer :column

      t.timestamps
    end
  end
end
