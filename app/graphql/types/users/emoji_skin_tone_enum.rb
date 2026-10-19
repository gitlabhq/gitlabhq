# frozen_string_literal: true

module Types
  module Users
    class EmojiSkinToneEnum < BaseEnum
      graphql_name 'EmojiSkinTone'
      description 'Default skin tone for emoji that have skin tone variants.'

      value 'DEFAULT', value: 'default', description: 'No skin tone. Emoji keep their default yellow.'
      value 'LIGHT', value: 'light', description: 'Light skin tone.'
      value 'MEDIUM_LIGHT', value: 'medium_light', description: 'Medium-light skin tone.'
      value 'MEDIUM', value: 'medium', description: 'Medium skin tone.'
      value 'MEDIUM_DARK', value: 'medium_dark', description: 'Medium-dark skin tone.'
      value 'DARK', value: 'dark', description: 'Dark skin tone.'
    end
  end
end
