# frozen_string_literal: true

module Gitlab
  module Ci
    module Variables
      module Downstream
        class Base
          def initialize(context)
            @context = context
          end

          private

          attr_reader :context
        end
      end
    end
  end
end
