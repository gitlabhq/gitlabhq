require 'database_cleaner'

DatabaseCleaner[:active_record].strategy = :deletion, { except: ['licenses'] }

Spinach.hooks.before_scenario do
  DatabaseCleaner.start
end

Spinach.hooks.after_scenario do
  DatabaseCleaner.clean
end
