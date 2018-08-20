module QA
  module Page
    module Validatable
      PageValidationError = Class.new(StandardError)

      def validate_elements_present!
        # get elements from self
        elements.each do |element|
          if element.required?
            base_page = self.new
            unless base_page.using_wait_time(10) { base_page.page.has_selector?(element.selector_css) }
              raise Validatable::PageValidationError, "#{element.name} expected on #{self.name} page"
            end
          end
        end
      end
    end
  end
end
