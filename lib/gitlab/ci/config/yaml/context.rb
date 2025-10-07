# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Yaml
        class Context
          attr_reader :variables, :component

          def initialize(variables: [], component: {})
            @variables = variables
            @component = component
          end
        end
      end
    end
  end
end
