require 'capybara/dsl'

module QA
  module Page
    class Base
      include Capybara::DSL
      include Scenario::Actable

      def refresh
        visit current_url
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

      def wait(css = '.application', time: 60)
        # This resolves cold boot / background tasks problems
        #
        Time.now.tap do |start|
          while Time.now - start < time
            break if page.has_css?(css, wait: 5)
            puts "Waiting for `#{css} on `#{current_url}`"
            refresh
          end
        end

        yield if block_given?
      end

      ##
      # If you want to use specific page class as an entrypoint
      # for Runtime::Browser.session, you need to implement this
      # method in a subclass.
      #
      def self.address
        raise NotImplementedError
      end

      ## TODO
      # When we navigate through pages, we want to check if we are on a
      # valid page everytime we instantiate a new Page object.
      #
      # See gitlab-org/gitlab-qa#111
      #
      # def self.pattern
      #   raise NotImplementedError
      # end
    end
  end
end
