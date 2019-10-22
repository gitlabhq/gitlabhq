# frozen_string_literal: true

module QA
  module Page
    class Validator
      ValidationError = Class.new(StandardError)

      Error = Struct.new(:page, :message) do
        def to_s
          "Error: #{page} - #{message}"
        end
      end

      def initialize(constant)
        @module = constant
      end

      def constants
        @consts ||= @module.constants.map do |const|
          @module.const_get(const, false)
        end
      end

      def descendants
        @descendants ||= constants.flat_map do |const|
          case const
          when Class
            const if const < Page::Base
          when Module
            Page::Validator.new(const).descendants
          end
        end.compact
      end

      def errors
        [].tap do |errors|
          descendants.each do |page|
            page.errors.each do |message|
              errors.push(Error.new(page.name, message))
            end
          end
        end
      end

      def validate!
        return if errors.none?

        raise ValidationError, 'Page views / elements validation error!'
      end
    end
  end
end
