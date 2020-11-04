# frozen_string_literal: true

module Gitlab
  module Tracking
    module Destinations
      class Base
        def event(category, action, label: nil, property: nil, value: nil, context: nil)
          raise NotImplementedError, "#{self} does not implement #{__method__}"
        end
      end
    end
  end
end
