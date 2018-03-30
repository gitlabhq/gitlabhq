desc 'GitLab | Sets up PostgreSQL'
task setup_postgresql: :environment do
  require Rails.root.join('db/migrate/20151007120511_namespaces_projects_path_lower_indexes')
  require Rails.root.join('db/migrate/20151008110232_add_users_lower_username_email_indexes')
  require Rails.root.join('db/migrate/20161212142807_add_lower_path_index_to_routes')
  require Rails.root.join('db/migrate/20170317203554_index_routes_path_for_like')
  require Rails.root.join('db/migrate/20170724214302_add_lower_path_index_to_redirect_routes')
  require Rails.root.join('db/migrate/20170503185032_index_redirect_routes_path_for_like')
  require Rails.root.join('db/migrate/20171220191323_add_index_on_namespaces_lower_name.rb')
  require Rails.root.join('db/migrate/20180215181245_users_name_lower_index.rb')
  require Rails.root.join('db/post_migrate/20180306164012_add_path_index_to_redirect_routes.rb')

  NamespacesProjectsPathLowerIndexes.new.up
  AddUsersLowerUsernameEmailIndexes.new.up
  AddLowerPathIndexToRoutes.new.up
  IndexRoutesPathForLike.new.up
  AddLowerPathIndexToRedirectRoutes.new.up
  IndexRedirectRoutesPathForLike.new.up
  AddIndexOnNamespacesLowerName.new.up
  UsersNameLowerIndex.new.up
  AddPathIndexToRedirectRoutes.new.up
end

desc 'GitLab | Generate PostgreSQL Password Hash'
task :postgresql_md5_hash do
  require 'digest'
  username = ENV.fetch('USERNAME') do |missing|
    puts "You must provide an username with '#{missing}' ENV variable"
    exit(1)
  end
  password = ENV.fetch('PASSWORD') do |missing|
    puts "You must provide a password with '#{missing}' ENV variable"
    exit(1)
  end
  hash = Digest::MD5.hexdigest("#{password}#{username}")
  puts "The MD5 hash of your database password for user: #{username} -> #{hash}"
end
