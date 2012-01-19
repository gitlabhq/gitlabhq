class FixNotableKey < ActiveRecord::Migration
  def change
    change_column :notes, :noteable_id, :integer, :limit => 11
  end
end
