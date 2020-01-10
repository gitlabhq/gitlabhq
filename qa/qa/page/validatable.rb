# frozen_string_literal: true

module QA
  module Page
    module Validatable
      PageValidationError = Class.new(StandardError)

      def validate_elements_present!
        base_page = self.new

        elements.each do |element|
          next unless element.required?

          unless base_page.wait(reload: false) { base_page.has_element?(element.name, wait: 15) }
            raise Validatable::PageValidationError, "#{element.name} did not appear on #{self.name} as expected"
          end
        end
      end
    end
  end
end
