require 'simplecov' unless ENV['CI']

if ENV['TRAVIS']
  require 'coveralls'
  Coveralls.wear!
end

ENV['RAILS_ENV'] = 'test'
require './config/environment'

require 'rspec'
require 'database_cleaner'
require 'spinach/capybara'
require 'sidekiq/testing/inline'


%w(stubbed_repository valid_commit select2_helper).each do |f|
  require Rails.root.join('spec', 'support', f)
end

Dir["#{Rails.root}/features/steps/shared/*.rb"].each {|file| require file}

WebMock.allow_net_connect!
#
# JS driver
#
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist
Spinach.hooks.on_tag("javascript") do
  ::Capybara.current_driver = ::Capybara.javascript_driver
  ::Capybara.default_wait_time = 5
end


DatabaseCleaner.strategy = :truncation

Spinach.hooks.before_scenario do
  # Use tmp dir for FS manipulations
  Gitlab.config.gitlab_shell.stub(repos_path: Rails.root.join('tmp', 'test-git-base-path'))
  Gitlab::Shell.any_instance.stub(:add_repository) do |path|
    create_temp_repo("#{Rails.root}/tmp/test-git-base-path/#{path}.git")
  end
  FileUtils.rm_rf Gitlab.config.gitlab_shell.repos_path
  FileUtils.mkdir_p Gitlab.config.gitlab_shell.repos_path
  DatabaseCleaner.start
end

Spinach.hooks.after_scenario do
  DatabaseCleaner.clean
end

Spinach.hooks.before_run do
  RSpec::Mocks::setup self

  include FactoryGirl::Syntax::Methods
end

def create_temp_repo(path)
  FileUtils.mkdir_p path
  command = "git init --quiet --bare #{path};"
  system(command)
end
