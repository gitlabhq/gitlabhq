# frozen_string_literal: true

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
