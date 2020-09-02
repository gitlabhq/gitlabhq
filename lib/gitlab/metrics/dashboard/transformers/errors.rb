# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Transformers
        TransformerError = Class.new(StandardError)

        module Errors
          class MissingAttribute < TransformerError
            def initialize(attribute_name)
              super("Missing attribute: '#{attribute_name}'")
            end
          end
        end
      end
    end
  end
end
