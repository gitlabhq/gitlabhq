# frozen_string_literal: true

RSpec.configure do |config|
  # Enable FactoryBot syntax
  config.include FactoryBot::Syntax::Methods

  # Load definitions
  config.before(:suite) do
    FactoryBot.find_definitions
  end
end
