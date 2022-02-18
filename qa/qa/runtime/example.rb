# frozen_string_literal: true

module QA
  module Runtime
    module Example
      extend self

      attr_accessor :current

      def location
        current.respond_to?(:location) ? current.location : 'unknown'
      end
    end
  end
end
