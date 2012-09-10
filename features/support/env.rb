ENV['RAILS_ENV'] = 'test'
require './config/environment'

require 'rspec'
require 'database_cleaner'

%w(gitolite_stub login_helpers stubbed_repository valid_commit).each do |f|
  require Rails.root.join('spec', 'support', f)
end

include LoginHelpers
include GitoliteStub

WebMock.allow_net_connect!

DatabaseCleaner.strategy = :truncation
Spinach.hooks.before_scenario { DatabaseCleaner.start }
Spinach.hooks.after_scenario  { DatabaseCleaner.clean }

Spinach.hooks.before_run do
  RSpec::Mocks::setup self

  stub_gitolite!
end
