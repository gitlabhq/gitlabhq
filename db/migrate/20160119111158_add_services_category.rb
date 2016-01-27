class AddServicesCategory < ActiveRecord::Migration
  def up
    add_column :services, :category, :string, default: 'common', null: false

    category = quote_column_name('category')
    type     = quote_column_name('type')

    execute <<-EOF
UPDATE services
SET #{category} = 'issue_tracker'
WHERE #{type} IN (
  'CustomIssueTrackerService',
  'GitlabIssueTrackerService',
  'IssueTrackerService',
  'JiraService',
  'RedmineService'
);
EOF

    execute <<-EOF
UPDATE services
SET #{category} = 'ci'
WHERE #{type} IN (
  'BambooService',
  'BuildkiteService',
  'CiService',
  'DroneCiService',
  'GitlabCiService',
  'TeamcityService'
);
    EOF

    add_index :services, :category
  end

  def down
    remove_column :services, :category
  end
end
