if ENV['SIMPLECOV']
  require 'simplecov'
end

if ENV['COVERALLS']
  require 'coveralls'
  Coveralls.wear_merged!
end

ENV['RAILS_ENV'] = 'test'
require './config/environment'
require 'rspec/expectations'
require 'sidekiq/testing/inline'

require_relative 'capybara'
require_relative 'db_cleaner'

%w(select2_helper test_env repo_helpers).each do |f|
  require Rails.root.join('spec', 'support', f)
end

Dir["#{Rails.root}/features/steps/shared/*.rb"].each { |file| require file }

WebMock.allow_net_connect!

Spinach.hooks.before_run do
  include RSpec::Mocks::ExampleMethods
  RSpec::Mocks.setup
  TestEnv.init(mailer: false)

  # skip pre-receive hook check so we can use
  # web editor and merge
  TestEnv.disable_pre_receive

  include FactoryGirl::Syntax::Methods
end
