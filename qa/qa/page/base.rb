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

      def click_element(name)
        find(Page::Element.new(name).selector_css).click
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
