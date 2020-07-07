# frozen_string_literal: true

module Gitlab
  module ClassAttributes
    extend ActiveSupport::Concern

    class_methods do
      protected

      # Returns an attribute declared on this class or its parent class.
      # This approach allows declared attributes to be inherited by
      # child classes.
      def get_class_attribute(name)
        class_attributes[name] || superclass_attributes(name)
      end

      private

      def class_attributes
        @class_attributes ||= {}
      end

      def superclass_attributes(name)
        return unless superclass.include? Gitlab::ClassAttributes

        superclass.get_class_attribute(name)
      end
    end
  end
end
