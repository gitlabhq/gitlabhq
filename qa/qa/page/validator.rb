module QA
  module Page
    class Validator
      ValidationError = Class.new(StandardError)
      Error = Struct.new(:page, :view, :message)

      def initialize(constant)
        @module = constant
      end

      def constants
        @consts ||= @module.constants.map do |const|
          @module.const_get(const)
        end
      end

      def descendants
        @descendants ||= constants.map do |const|
          case const
          when Class
            const if const < Page::Base
          when Module
            Page::Validator.new(const).descendants
          end
        end

        @descendants.flatten.compact
      end

      def errors
        @errors ||= Array.new.tap do |errors|
          descendants.each do |page|
            page.views.each do |view|
              view.errors.each do |error|
                errors.push(Error.new(page, view, error))
              end
            end
          end
        end
      end

      def validate!
        message = <<~EOS
          We found validation errors!
        EOS

        raise ValidationError, message if errors.any?
      end
    end
  end
end
