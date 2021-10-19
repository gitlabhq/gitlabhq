# frozen_string_literal: true

# Gitlab::EmojiNameValidator
#
# Validates that the provided value matches an indexed emoji alpha code
#
# @example Usage
#    class AwardEmoji < ApplicationRecord
#      validate :name, 'gitlab/emoji_name':  true
#    end
module Gitlab
  class EmojiNameValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      unless TanukiEmoji.find_by_alpha_code(value.to_s)
        record.errors.add(attribute, (options[:message] || 'is not a valid emoji name'))
      end
    end
  end
end
