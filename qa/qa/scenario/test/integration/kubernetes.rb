# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Integration
        class Kubernetes < Test::Instance::All
          tags :kubernetes
        end
      end
    end
  end
end
