# RSpec.configure do |config|

#   config.around(:each) do |example|
#     DatabaseCleaner.strategy = :transaction
#     DatabaseCleaner.clean_with(:truncation)
#     DatabaseCleaner.cleaning do
#       example.run
#     end
#   end

#   config.around(:each, js: true) do |example|
#     DatabaseCleaner.strategy = :truncation
#     DatabaseCleaner.clean_with(:truncation)
#     DatabaseCleaner.cleaning do
#       example.run
#     end
#   end
# end
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, :js => true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
