require 'capybara/dsl'

module QA
  module Page
    class Base
      include Capybara::DSL
      include Scenario::Actable
      extend SingleForwardable

      def_delegators :evaluator, :view, :views

      def refresh
        visit current_url
      end

      def wait(max: 60, time: 1, reload: true)
        start = Time.now

        while Time.now - start < max
          result = yield
          return result if result

          sleep(time)

          refresh if reload
        end

        false
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

      # Returns true if successfully GETs the given URL
      # Useful because `page.status_code` is unsupported by our driver, and
      # we don't have access to the `response` to use `have_http_status`.
      def asset_exists?(url)
        page.execute_script <<~JS
          xhr = new XMLHttpRequest();
          xhr.open('GET', '#{url}', true);
          xhr.send();
        JS

        return false unless wait(time: 0.5, max: 60, reload: false) do
          page.evaluate_script('xhr.readyState == XMLHttpRequest.DONE')
        end

        page.evaluate_script('xhr.status') == 200
      end

      def find_element(name)
        find(element_selector_css(name))
      end

      def all_elements(name)
        all(element_selector_css(name))
      end

      def click_element(name)
        find_element(name).click
      end

      def fill_element(name, content)
        find_element(name).set(content)
      end

      def within_element(name)
        page.within(element_selector_css(name)) do
          yield
        end
      end

      def element_selector_css(name)
        Page::Element.new(name).selector_css
      end

      def self.path
        raise NotImplementedError
      end

      def self.evaluator
        @evaluator ||= Page::Base::DSL.new
      end

      def self.errors
        if views.empty?
          return ["Page class does not have views / elements defined!"]
        end

        views.map(&:errors).flatten
      end

      def self.elements
        views.map(&:elements).flatten
      end

      class DSL
        attr_reader :views

        def initialize
          @views = []
        end

        def view(path, &block)
          Page::View.evaluate(&block).tap do |view|
            @views.push(Page::View.new(path, view.elements))
          end
        end
      end
    end
  end
end
