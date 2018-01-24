require 'database_cleaner'

<<<<<<< HEAD
DatabaseCleaner[:active_record].strategy = :deletion, { except: ['licenses'] }
=======
DatabaseCleaner[:active_record].strategy = :deletion
>>>>>>> upstream/master

Spinach.hooks.before_scenario do
  DatabaseCleaner.start
end

Spinach.hooks.after_scenario do
  DatabaseCleaner.clean
end
