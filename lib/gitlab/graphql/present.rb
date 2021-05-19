# frozen_string_literal: true

module Gitlab
  module Graphql
    module Present
      extend ActiveSupport::Concern
      prepended do
        def self.present_using(kls)
          @presenter_class = kls
        end

        def self.presenter_class
          @presenter_class || superclass.try(:presenter_class)
        end

        def self.present(object, attrs)
          klass = presenter_class
          return object if !klass || object.is_a?(klass)

          klass.new(object, **attrs)
        end
      end

      def unpresented
        unwrapped || object
      end

      def present(object_type, attrs)
        return unless object_type.respond_to?(:present)

        self.unwrapped ||= object
        # @object belongs to Schema::Object, which does not expose a writer.
        @object = object_type.present(unwrapped, attrs) # rubocop: disable Gitlab/ModuleWithInstanceVariables
      end

      private

      attr_accessor :unwrapped
    end
  end
end
