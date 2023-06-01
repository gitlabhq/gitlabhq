# frozen_string_literal: true

module Gitlab
  module Sentence
    extend self
    # Wraps ActiveSupport's Array#to_sentence to convert the given array to a
    # comma-separated sentence joined with localized 'or' Strings instead of 'and'.
    def to_exclusive_sentence(array)
      array.to_sentence(two_words_connector: _(' or '), last_word_connector: _(', or '))
    end
  end
end
