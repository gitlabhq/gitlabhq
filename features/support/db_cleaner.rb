require 'database_cleaner'

<<<<<<< HEAD
DatabaseCleaner.strategy = :truncation, { except: ['licenses'] }
=======
DatabaseCleaner[:active_record].strategy = :truncation
>>>>>>> ce/master

Spinach.hooks.before_scenario do
  DatabaseCleaner.start
end

Spinach.hooks.after_scenario do
  DatabaseCleaner.clean
end
