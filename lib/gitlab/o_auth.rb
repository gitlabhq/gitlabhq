module Gitlab
  module OAuth
    SignupDisabledError = Class.new(StandardError)
    SigninDisabledForProviderError = Class.new(StandardError)
  end
end
