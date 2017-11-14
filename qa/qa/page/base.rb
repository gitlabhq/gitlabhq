require 'capybara/dsl'

module QA
  module Page
    class Base
      include Capybara::DSL
      include Scenario::Actable

      def refresh
        visit current_path
      end

      def scroll_to(css, &block)
        page.execute_script <<~JS
          document.getElementsByClassName("#{css.sub(/^\./, '')}")[0].scrollIntoView();
        JS

        page.within(css, &block)
      end
    end
  end
end
