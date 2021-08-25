# frozen_string_literal: true

module QA
  module Support
    module Matchers
      class HaveText
        def initialize(expected_text, **kwargs)
          @expected_text = expected_text
          @kwargs = kwargs
        end

        def matches?(actual)
          @actual = wrap(actual)
          @actual.has_text?(@expected_text, **@kwargs)
        end

        def does_not_match?(actual)
          @actual = wrap(actual)
          @actual.has_no_text?(@expected_text, **@kwargs)
        end

        def failure_message
          "expected to find text \"#{@expected_text}\" in \"#{normalized_actual_text}\""
        end

        def failure_message_when_negated
          "expected not to find text \"#{@expected_text}\" in \"#{normalized_actual_text}\""
        end

        def normalized_actual_text
          @actual.text.gsub(/\s+/, " ")
        end

        # From https://github.com/teamcapybara/capybara/blob/fe5940c6afbfe32152df936ce03ad1371ae05354/lib/capybara/rspec/matchers/base.rb#L66
        def wrap(actual)
          actual = actual.to_capybara_node if actual.respond_to?(:to_capybara_node)
          @context_el = if actual.respond_to?(:has_selector?)
                          actual
                        else
                          Capybara.string(actual.to_s)
                        end
        end
      end

      def have_text(text, **kwargs) # rubocop:disable Naming/PredicateName
        HaveText.new(text, **kwargs)
      end

      alias_method :have_content, :have_text
    end
  end
end
