# frozen_string_literal: true

require_relative '../../tooling/danger/rubocop_inline_disable_suggestion'

module Danger
  class Rubocop < ::Danger::Plugin
    # Put the helper code somewhere it can be tested
    def add_suggestions_for(filename)
      Tooling::Danger::RubocopInlineDisableSuggestion.new(filename, context: self).suggest
    end
  end
end
