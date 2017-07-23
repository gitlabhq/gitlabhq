module LoginHelpers
  # After inclusion, IntegrationHelpers calls these two methods that aren't
  # supported by Spinach, so we perform the end results ourselves
  class << self
    def setup(*args)
      Spinach.hooks.before_scenario do
        Warden.test_mode!
      end
    end

    def teardown(*args)
      Spinach.hooks.after_scenario do
        Warden.test_reset!
      end
    end
  end

  include Devise::Test::IntegrationHelpers
end
