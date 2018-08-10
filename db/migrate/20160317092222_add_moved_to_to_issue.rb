class AddMovedToToIssue < ActiveRecord::Migration
  def change
    add_reference :issues, :moved_to, references: :issues # rubocop:disable Migration/AddReference
  end
end
