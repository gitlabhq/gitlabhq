# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      module Defaults
        def identifier
          self.class.name.demodulize.underscore.to_sym
        end

        # :nocov: the class including this concern is expected to test this method.
        def title
          raise NotImplementedError, "Expected #{self.name} to implement title"
        end
        # :nocov:

        # :nocov: the class including this concern is expected to test this method.
        def value
          raise NotImplementedError, "Expected #{self.name} to implement value"
        end
        # :nocov:

        def links
          []
        end
      end
    end
  end
end
