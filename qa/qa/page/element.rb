# frozen_string_literal: true

require 'active_support/core_ext/array/extract_options'

module QA
  module Page
    # Gitlab element css selector builder using data-testid attribute
    #
    class Element
      attr_reader :name, :attributes

      def initialize(name, *options)
        @name = name
        @attributes = options.extract_options!

        options.each do |option|
          @attributes[:pattern] = option if option.is_a?(String) || option.is_a?(Regexp)
        end
      end

      def required?
        !!@attributes[:required]
      end

      def selector_css
        %([data-testid="#{name}"]#{additional_selectors})
      end

      def matches?(line)
        if expression
          !!(line =~ /["']#{name}['"]|#{expression}/)
        else
          !!(line =~ /["']#{name}['"]/)
        end
      end

      private

      def expression
        if @attributes[:pattern].is_a?(String)
          @_regexp ||= Regexp.new(Regexp.escape(@attributes[:pattern]))
        else
          @attributes[:pattern]
        end
      end

      def additional_selectors
        @attributes.dup.delete_if { |attr| attr == :pattern || attr == :required }.map do |key, value|
          %([data-qa-#{key.to_s.tr('_', '-')}="#{value}"])
        end.join
      end
    end
  end
end
