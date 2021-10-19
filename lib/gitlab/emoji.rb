# frozen_string_literal: true

module Gitlab
  module Emoji
    extend self

    # When updating emoji assets increase the version below
    # and update the version number in `app/assets/javascripts/emoji/index.js`
    EMOJI_VERSION = 1

    # Return a Pathname to emoji's current versioned folder
    #
    # @return [Pathname] Absolute Path to versioned emojis folder in `public`
    def emoji_public_absolute_path
      Rails.root.join("public/-/emojis/#{EMOJI_VERSION}")
    end

    def emoji_image_tag(name, src)
      image_options = {
        class:  'emoji',
        src:    src,
        title:  ":#{name}:",
        alt:    ":#{name}:",
        height: 20,
        width:  20,
        align:  'absmiddle'
      }

      ActionController::Base.helpers.tag(:img, image_options)
    end

    # CSS sprite fallback takes precedence over image fallback
    # @param [TanukiEmoji::Character] emoji
    # @param [Hash] options
    def gl_emoji_tag(emoji, options = {})
      return unless emoji

      data = {
        name: emoji.name,
        unicode_version: emoji.unicode_version
      }
      options = { title: emoji.description, data: data }.merge(options)

      ActionController::Base.helpers.content_tag('gl-emoji', emoji.codepoints, options)
    end

    def custom_emoji_tag(name, image_source)
      data = {
        name: name
      }

      ActionController::Base.helpers.content_tag('gl-emoji', title: name, data: data) do
        emoji_image_tag(name, image_source).html_safe
      end
    end
  end
end
