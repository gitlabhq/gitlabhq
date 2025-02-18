# frozen_string_literal: true

module Integrations
  module Instance
    class Harbor < Integration
      include Integrations::Base::Harbor
    end
  end
end
