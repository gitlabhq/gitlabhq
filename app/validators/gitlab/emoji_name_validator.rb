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
      return if valid_tanuki_emoji?(value)
      return if valid_custom_emoji?(record, value)

      record.errors.add(attribute, (options[:message] || 'is not a valid emoji name'))
    end

    private

    def valid_tanuki_emoji?(value)
      TanukiEmoji.find_by_alpha_code(value.to_s)
    end

    def valid_custom_emoji?(record, value)
      resource = record.try(:resource_parent)

      CustomEmoji.for_resource(resource).by_name(value.to_s).any?
    end
  end
end
