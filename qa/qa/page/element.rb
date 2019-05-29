# frozen_string_literal: true

require 'active_support/core_ext/array/extract_options'

module QA
  module Page
    class Element
      attr_reader :name, :attributes

      def initialize(name, *options)
        @name = name
        @attributes = options.extract_options!
        @attributes[:pattern] ||= selector

        options.each do |option|
          if option.is_a?(String) || option.is_a?(Regexp)
            @attributes[:pattern] = option
          end
        end
      end

      def selector
        "qa-#{@name.to_s.tr('_', '-')}"
      end

      def required?
        !!@attributes[:required]
      end

      def selector_css
        "[data-qa-selector='#{@name}'],.#{selector}"
      end

      def expression
        if @attributes[:pattern].is_a?(String)
          @_regexp ||= Regexp.new(Regexp.escape(@attributes[:pattern]))
        else
          @attributes[:pattern]
        end
      end

      def matches?(line)
        !!(line =~ /["']#{name}['"]|#{expression}/)
      end
    end
  end
end
