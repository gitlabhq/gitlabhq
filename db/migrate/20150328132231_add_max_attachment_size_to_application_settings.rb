class AddMaxAttachmentSizeToApplicationSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :application_settings, :max_attachment_size, :integer, default: 10, null: false
  end
end
