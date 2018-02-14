RSpec.configure do |config|
  config.before(:suite) do
    FactoryBot.definition_file_paths = [
      Rails.root.join('ee', 'spec', 'factories')
    ]
    FactoryBot.find_definitions
  end
end
