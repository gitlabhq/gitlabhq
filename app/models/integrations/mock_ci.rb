# frozen_string_literal: true

# For an example companion mocking service, see https://gitlab.com/gitlab-org/gitlab-mock-ci-service
module Integrations
  class MockCi < Integration
    include Integrations::Base::MockCi
  end
end
