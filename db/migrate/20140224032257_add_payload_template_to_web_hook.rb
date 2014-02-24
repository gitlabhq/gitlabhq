class AddPayloadTemplateToWebHook < ActiveRecord::Migration
  def change
    add_column :web_hooks, :payload_template, :text
  end
end
