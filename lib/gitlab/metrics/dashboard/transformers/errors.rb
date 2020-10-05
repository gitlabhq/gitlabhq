# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Transformers
        module Errors
          BaseError = Class.new(StandardError)

          class MissingAttribute < BaseError
            def initialize(attribute_name)
              super("Missing attribute: '#{attribute_name}'")
            end
          end
        end
      end
    end
  end
end
