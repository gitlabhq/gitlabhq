# frozen_string_literal: true

module Integrations
  module Instance
    class MockCi < Integration
      include Integrations::Base::MockCi
    end
  end
end
