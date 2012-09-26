# Include cookbook dependencies
%w{ gitlab::gitolite build-essential
    readline openssh xml zlib python::package python::pip
    redisio::install redisio::enable }.each do |requirement|
  include_recipe requirement
end

# symlink redis-cli into /usr/bin (needed for gitlab hooks to work)
link "/usr/bin/redis-cli" do
  to "/usr/local/bin/redis-cli"
end

# Install required packages for Gitlab
node['gitlab']['packages'].each do |pkg|
  package pkg
end

# Install gitlab necessary gems (after packages...)
rvm_gem "bundler" do
  ruby_string "ruby-1.9.3"
  user "vagrant"
  action :install
end

rvm_gem "charlock_holmes" do
  ruby_string "ruby-1.9.3"
  user "vagrant"
  version "0.6.8"
  action :install
end

# Install sshkey gem into chef
chef_gem "sshkey" do
  action :install
end

# Install pygments from pip
python_pip "pygments" do
  action :install
end

# Add the gitlab user to the "git" group
group node['gitlab']['git_group'] do
  members node['gitlab']['user']
end

# Create a $HOME/.ssh folder
directory "#{node['gitlab']['home']}/.ssh" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0700
end

# Generate and deploy ssh public/private keys
Gem.clear_paths
if File.exists?(node['gitlab']['home'] + '/.ssh/id_rsa.pub')
  require 'ostruct'
  gitlab_sshkey = OpenStruct.new
  gitlab_sshkey.ssh_private_key = File.open(node['gitlab']['home'] + '/.ssh/id_rsa', 'rb').read
  gitlab_sshkey.ssh_public_key = File.open(node['gitlab']['home'] + '/.ssh/id_rsa.pub', 'rb').read
else
  require 'sshkey'
  gitlab_sshkey = SSHKey.generate(:type => 'RSA', :comment => "#{node['gitlab']['user']}@#{node['fqdn']}")
end

node.set_unless['gitlab']['public_key'] = gitlab_sshkey.ssh_public_key

# Render private key template
template "#{node['gitlab']['home']}/.ssh/id_rsa" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  variables(
    :private_key => gitlab_sshkey.private_key
  )
  mode 0600
  not_if { File.exists?("#{node['gitlab']['home']}/.ssh/id_rsa") }
end

# Render public key template for gitlab user
template "#{node['gitlab']['home']}/.ssh/id_rsa.pub" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0644
  variables(
    :public_key => node['gitlab']['public_key']
  )
end

# Render public key template for gitolite user
template "#{node['gitlab']['git_home']}/gitlab.pub" do
  source "id_rsa.pub.erb"
  owner node['gitlab']['git_user']
  group node['gitlab']['git_group']
  mode 0644
  variables(
    :public_key => node['gitlab']['public_key']
  )
end

# Configure gitlab user to auto-accept localhost SSH keys
template "#{node['gitlab']['home']}/.ssh/config" do
  source "ssh_config.erb"
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0644
  variables(
    :fqdn => node['fqdn'],
    :trust_local_sshkeys => node['gitlab']['trust_local_sshkeys']
  )
end

# Sorry for this ugliness.
# It seems maybe something is wrong with the 'gitolite setup' script.
# This was implemented as a workaround.
execute "install-gitlab-key" do
  command "su - #{node['gitlab']['git_user']} -c 'perl #{node['gitlab']['gitolite_home']}/src/gitolite setup -pk #{node['gitlab']['git_home']}/gitlab.pub'"
  user "root"
  cwd node['gitlab']['git_home']
  not_if "grep -q '#{node['gitlab']['user']}' #{node['gitlab']['git_home']}/.ssh/authorized_keys"
end

# Create tmp/repositories/
#
# Uses host user/group id to workaround Vagrant's inability to set the NFS
# share on the virtual machine to the vagrant user.
directory "#{node['gitlab']['app_home']}/tmp/repositories" do
  user node['gitlab']['host_user_id']
  group node['gitlab']['host_group_id']
  mode "0755"
  recursive true
  action :create
end

# Render gitlab config file
template "#{node['gitlab']['app_home']}/config/gitlab.yml" do
  user node['gitlab']['host_user_id']
  group node['gitlab']['host_group_id']
  mode 0644
  variables(
    :fqdn => node['fqdn'],
    :https_boolean => node['gitlab']['https'],
    :git_user => node['gitlab']['git_user'],
    :git_home => node['gitlab']['git_home']
  )
end

# Use mysql as our database
template "#{node['gitlab']['app_home']}/config/database.yml" do
  source 'database.yml'
  user node['gitlab']['host_user_id']
  group node['gitlab']['host_group_id']
  mode 0644
end

# Database information
database_connexion = { :host     => 'localhost',
                       :username => 'root',
                       :password => node['mysql']['server_root_password'] }

# Create mysql user vagrant
mysql_database_user 'vagrant' do
  connection database_connexion
  password 'vagrant'
  action :create
end

# Create databases and users
%w{ gitlabhq_production gitlabhq_development gitlabhq_test }.each do |db|
  mysql_database "#{db}" do
    connection database_connexion
    action :create
  end
end

# grant all privelages on all databases/tables from localhost to vagrant
mysql_database_user 'vagrant' do
  connection database_connexion
  password 'vagrant'
  action :grant
end

# Render Xvfb start service
template "/etc/init.d/xvfb" do
  owner "root"
  group "root"
  mode 0755
  source "xvfb.sh.erb"
end

template "/etc/bash.bashrc" do
  owner "root"
  group "root"
  mode 0755
  source "bash.bashrc"
end

# Xvfb start
service "xvfb" do
  action :start
end

# Install Gems with bundle install
# `execute` doesn't use the user environment and so this is a work around to do
# as if it was vagrant and not root.
# http://tickets.opscode.com/browse/CHEF-2288?page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#issue-tabs
execute "gitlab-bundle-install" do
  command "su -l -c 'cd #{node['gitlab']['app_home']} && bundle install' vagrant"
  cwd node['gitlab']['app_home']
  user 'root'
end

%w{ development test }.each do |env|
  # Setup database
  execute "gitlab-#{env}-setup" do
    command "su -l -c 'cd #{node['gitlab']['app_home']} &&
      bundle exec rake db:setup RAILS_ENV=#{env}' vagrant"
    cwd node['gitlab']['app_home']
    user 'root'
  end
end

# Seed database
execute "gitlab-test-seed" do
  command "su -l -c 'cd #{node['gitlab']['app_home']} &&
    bundle exec rake db:seed_fu RAILS_ENV=test' vagrant"
  cwd node['gitlab']['app_home']
  user 'root'
end
