# frozen_string_literal: true

module RuboCop
  module Cop
    class RubyInterpolationInTranslation < RuboCop::Cop::Cop
      MSG = "Don't use ruby interpolation \#{} inside translated strings, instead use \%{}"

      TRANSLATION_METHODS = ':_ :s_ :N_ :n_'
      RUBY_INTERPOLATION_REGEX = /.*\#\{.*\}/

      def_node_matcher :translation_method?, <<~PATTERN
        (send nil? {#{TRANSLATION_METHODS}} $dstr ...)
      PATTERN

      def_node_matcher :plural_translation_method?, <<~PATTERN
        (send nil? :n_ str $dstr ...)
      PATTERN

      def on_send(node)
        interpolation = translation_method?(node) || plural_translation_method?(node)
        return unless interpolation

        interpolation.descendants.each do |possible_violation|
          add_offense(possible_violation, message: MSG) if possible_violation.type != :str
        end
      end
    end
  end
end
