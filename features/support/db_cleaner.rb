require 'database_cleaner'

DatabaseCleaner.strategy = :truncation

Spinach.hooks.before_scenario do
  DatabaseCleaner.start
end

Spinach.hooks.after_scenario do
  DatabaseCleaner.clean
end
