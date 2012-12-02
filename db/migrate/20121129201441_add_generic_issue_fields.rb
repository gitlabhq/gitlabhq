class AddGenericIssueFields < ActiveRecord::Migration
  def change
    create_table :generic_issue_fields do |t|
      t.integer     :id, :null => false
      t.integer     :project_id, :null => false
      t.string      :title, :null => false
      t.string      :description
      t.integer     :default_value
      t.boolean     :mandatory
    end
    create_table :generic_issue_field_values do |t|
      t.integer    :id, :null => false
      t.integer    :generic_issue_field_id, :null => false
      t.string     :title, :null => false
      t.string     :description
    end
    create_table :issue_generic_issue_field_values do |t|
      t.integer    :issue_id, :null => false
      t.integer    :generic_issue_field_value_id, :null => false
    end
  end
end
