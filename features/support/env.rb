ENV['RAILS_ENV'] = 'test'
require './config/environment'

require 'rspec'
require 'database_cleaner'
require 'spinach/capybara'

%w(gitolite_stub stubbed_repository valid_commit).each do |f|
  require Rails.root.join('spec', 'support', f)
end

Dir["#{Rails.root}/features/steps/shared/*.rb"].each {|file| require file}

#
# Stub gitolite
#
include GitoliteStub

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
  Gitlab.config.gitolite.stub(repos_path: Rails.root.join('tmp', 'test-git-base-path'))
  FileUtils.rm_rf Gitlab.config.gitolite.repos_path
  FileUtils.mkdir_p Gitlab.config.gitolite.repos_path
end

Spinach.hooks.after_scenario do
  DatabaseCleaner.clean
end

Spinach.hooks.before_run do
  RSpec::Mocks::setup self

  include FactoryGirl::Syntax::Methods

  stub_gitolite!
end
