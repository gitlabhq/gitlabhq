# frozen_string_literal: true

require 'capybara/dsl'

module QA
  module Vendor
    module Page
      class Base
        include Capybara::DSL
        include Scenario::Actable
      end
    end
  end
end
