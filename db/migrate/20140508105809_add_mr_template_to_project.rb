class AddMrTemplateToProject < ActiveRecord::Migration
  def change
    add_column :projects, :merge_requests_template, :text
  end
end
