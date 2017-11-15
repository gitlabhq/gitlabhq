require 'capybara/dsl'

module QA
  module Page
    class Base
      include Capybara::DSL
      include Scenario::Actable

      def refresh
        visit current_path
      end

      def scroll_to(selector)
        if selector.start_with?('.')
          page.execute_script <<~JS
            document.getElementsByClassName("#{selector.sub(/^\./, '')}")[0].scrollIntoView();
          JS
        else
          page.execute_script <<~JS
            document.getElementById("#{selector}").scrollIntoView();
          JS
        end

        page.within(selector) { yield } if block_given?
      end
    end
  end
end
