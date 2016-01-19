class AddServicesDefault < ActiveRecord::Migration
  def up
    add_column :services, :default, :boolean, default: false

    default = quote_column_name('default')
    type    = quote_column_name('type')

    execute <<-EOF
UPDATE services
SET #{default} = true
WHERE #{type} = 'GitlabIssueTrackerService'
EOF

    add_index :services, :default
  end

  def down
    remove_column :services, :default
  end
end
