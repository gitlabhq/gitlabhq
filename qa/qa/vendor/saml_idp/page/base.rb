# frozen_string_literal: true

module QA
  module Vendor
    module SAMLIdp
      module Page
        class Base
          include Capybara::DSL
          include Scenario::Actable
        end
      end
    end
  end
end
