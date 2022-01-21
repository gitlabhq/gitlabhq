# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      class Base
        def initialize(project:, options:)
          @project = project
          @options = options
        end

        def identifier
          self.class.name.demodulize.underscore.to_sym
        end

        def title
          raise NotImplementedError, "Expected #{self.name} to implement title"
        end

        def value
          raise NotImplementedError, "Expected #{self.name} to implement value"
        end

        def links
          []
        end

        private

        attr_reader :project, :options
      end
    end
  end
end
