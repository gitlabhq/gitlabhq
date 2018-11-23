class AddMovedToToIssue < ActiveRecord::Migration[4.2]
  def change
    add_reference :issues, :moved_to, references: :issues # rubocop:disable Migration/AddReference
  end
end
