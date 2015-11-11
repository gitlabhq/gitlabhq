require Rails.root.join('db/migrate/20151007120511_namespaces_projects_path_lower_indexes')
require Rails.root.join('db/migrate/20151008110232_add_users_lower_username_email_indexes')

desc 'GitLab | Sets up PostgreSQL'
task setup_postgresql: :environment do
  NamespacesProjectsPathLowerIndexes.new.up
  AddUsersLowerUsernameEmailIndexes.new.up
end
