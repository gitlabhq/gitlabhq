# frozen_string_literal: true

module QA
  module Page
    module Validatable
      PageValidationError = Class.new(StandardError)

      def validate_elements_present!
        base_page = self.new

        elements.each do |element|
          next unless element.required?

          # TODO: this wait needs to be replaced by the wait class
          unless base_page.has_element?(element.name, wait: 60)
            raise Validatable::PageValidationError, "#{element.name} did not appear on #{self.name} as expected"
          end
        end
      end
    end
  end
end
