# frozen_string_literal: true

module Gitlab
  module Audit
    class Target
      delegate :id, to: :@object

      def initialize(object)
        @object = object
      end

      def type
        @object.class.name
      end

      def details
        @object.try(:name) || @object.try(:audit_details) || 'unknown'
      end
    end
  end
end
