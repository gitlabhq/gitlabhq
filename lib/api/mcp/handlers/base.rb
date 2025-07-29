# frozen_string_literal: true

module API
  module Mcp
    module Handlers
      class Base
        attr_reader :params

        def initialize(params)
          @params = params
        end

        def invoke
          raise NoMethodError
        end
      end
    end
  end
end
