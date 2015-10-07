require Rails.root.join('db/migrate/20151007120511_namespaces_projects_path_lower_indexes')

desc 'GitLab | Sets up PostgreSQL'
task setup_postgresql: :environment do
  NamespacesProjectsPathLowerIndexes.new.up
end
