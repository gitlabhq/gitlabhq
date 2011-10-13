class AddAttachmentToNote < ActiveRecord::Migration
  def change
    add_column :notes, :attachment, :string
  end
end
