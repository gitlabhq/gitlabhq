# frozen_string_literal: true

module Gitlab
  module Utils
    # Converts a class into the string representation of its name
    # Example: `ClassNameConverter.new(Ci::SecureFile).string_representation` returns "ci_secure_file"
    class ClassNameConverter
      def initialize(klass)
        @klass = klass
      end

      def string_representation
        klass.name.underscore.tr('/', '_')
      end

      private

      attr_reader :klass
    end
  end
end
