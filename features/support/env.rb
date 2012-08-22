require 'simplecov'
SimpleCov.start 'rails'

require 'cucumber/rails'
require 'webmock/cucumber'
WebMock.allow_net_connect!

require Rails.root.join 'spec/monkeypatch'
require Rails.root.join 'spec/factories'
require Rails.root.join 'spec/support/login'
require Rails.root.join 'spec/support/valid_commit'

Capybara.default_selector = :css
Capybara.javascript_driver = :webkit

# By default, any exception happening in your Rails application will bubble up
# to Cucumber so that your scenario will fail. This is a different from how
# your application behaves in the production environment, where an error page will
# be rendered instead.
#
# Sometimes we want to override this default behaviour and allow Rails to rescue
# exceptions and display an error page (just like when the app is running in production).
# Typical scenarios where you want to do this is when you test your error pages.
# There are two ways to allow Rails to rescue exceptions:
#
# 1) Tag your scenario (or feature) with @allow-rescue
#
# 2) Set the value below to true. Beware that doing this globally is not
# recommended as it will mask a lot of errors for you!
#
ActionController::Base.allow_rescue = false

# Remove/comment out the lines below if your app doesn't have a database.
# For some databases (like MongoDB and CouchDB) you may need to use :truncation instead.
begin
  DatabaseCleaner.strategy = :transaction
rescue NameError
  raise "You need to add database_cleaner to your Gemfile (in the :test group) if you wish to use it."
end

Cucumber::Rails::Database.javascript_strategy = :truncation

require 'headless'

headless = Headless.new
headless.start

require 'cucumber/rspec/doubles'
