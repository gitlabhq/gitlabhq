module QA
  module Page
    class Validator
      def initialize(page)
        @page = page
        @views = page.views
      end

      def errors
        @errors ||= @views.map do |view|
        end
      end

      def message
      end
    end
  end
end
