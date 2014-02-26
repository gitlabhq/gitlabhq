class AddAttachmentToIssue < ActiveRecord::Migration
  def change
    add_column :issues, :attachment, :string
  end
end
