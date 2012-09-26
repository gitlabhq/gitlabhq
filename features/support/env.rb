ENV['RAILS_ENV'] = 'test'
require './config/environment'

require 'rspec'
require 'database_cleaner'
require 'spinach/capybara'

%w(gitolite_stub stubbed_repository valid_commit).each do |f|
  require Rails.root.join('spec', 'support', f)
end

Dir["#{Rails.root}/features/steps/shared/*.rb"].each {|file| require file}

include GitoliteStub

WebMock.allow_net_connect!
Capybara.javascript_driver = :webkit

DatabaseCleaner.strategy = :truncation
Spinach.hooks.before_scenario { DatabaseCleaner.start }
Spinach.hooks.after_scenario  { DatabaseCleaner.clean }

Spinach.hooks.before_run do
  RSpec::Mocks::setup self

  include FactoryGirl::Syntax::Methods

  stub_gitolite!
end
