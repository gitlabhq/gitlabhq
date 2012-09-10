ENV['RAILS_ENV'] = 'test'
require './config/environment'

require 'rspec'
require 'database_cleaner'

%w(login_helpers stubbed_repository).each do |f|
  require Rails.root.join('spec', 'support', f)
end

include LoginHelpers

DatabaseCleaner.strategy = :transaction
Spinach.hooks.before_scenario { DatabaseCleaner.start }
Spinach.hooks.after_scenario  { DatabaseCleaner.clean }
