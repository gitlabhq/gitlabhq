class AddIssuesTemplateToProject < ActiveRecord::Migration
  def change
    add_column :projects, :issues_template, :text
  end
end
