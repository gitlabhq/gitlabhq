module StrategyHelpers
  include Rack::Test::Methods
  include ActionDispatch::Assertions::ResponseAssertions
  include Shoulda::Matchers::ActionController
  include OmniAuth::Test::StrategyTestCase

  def post(*args)
    super.tap do
      @response = ActionDispatch::TestResponse.from_response(last_response) # rubocop:disable Gitlab/ModuleWithInstanceVariables
    end
  end

  def auth_hash
    last_request.env['omniauth.auth']
  end
end

RSpec.configure do |config|
  config.include StrategyHelpers, type: :strategy

  config.around(:all, type: :strategy) do |example|
    begin
      original_mode = OmniAuth.config.test_mode
      original_on_failure = OmniAuth.config.on_failure

      OmniAuth.config.test_mode = false
      OmniAuth.config.on_failure = OmniAuth::FailureEndpoint

      example.run
    ensure
      OmniAuth.config.test_mode = original_mode
      OmniAuth.config.on_failure = original_on_failure
    end
  end
end
