require 'capybara/dsl'

module QA
  module Page
    class Base
      include Capybara::DSL
      include Scenario::Actable

      def refresh
        visit current_url
      end

      def wait(css = '.application', time: 60)
        Time.now.tap do |start|
          while Time.now - start < time
            break if page.has_css?(css, wait: 5)

            refresh
          end
        end

        yield if block_given?
      end

      def scroll_to(selector, text: nil)
        page.execute_script <<~JS
          var elements = Array.from(document.querySelectorAll('#{selector}'));
          var text = '#{text}';

          if (text.length > 0) {
            elements.find(e => e.textContent === text).scrollIntoView();
          } else {
            elements[0].scrollIntoView();
          }
        JS

        page.within(selector) { yield } if block_given?
      end

      def self.path
        raise NotImplementedError
      end
    end
  end
end
