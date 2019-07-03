desc 'GitLab | Sets up PostgreSQL'
task setup_postgresql: :environment do
  require Rails.root.join('db/migrate/20180215181245_users_name_lower_index.rb')
  require Rails.root.join('db/migrate/20180504195842_project_name_lower_index.rb')
  require Rails.root.join('db/post_migrate/20180306164012_add_path_index_to_redirect_routes.rb')

  UsersNameLowerIndex.new.up
  ProjectNameLowerIndex.new.up
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
