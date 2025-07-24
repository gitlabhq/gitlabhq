# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Yaml
        class Context
          attr_reader :variables

          def initialize(variables: [])
            @variables = variables
          end
        end
      end
    end
  end
end
