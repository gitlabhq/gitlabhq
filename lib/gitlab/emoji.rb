# frozen_string_literal: true

module Gitlab
  module Emoji
    extend self

    # When updating emoji assets increase the version below
    # and update the version number in `app/assets/javascripts/emoji/index.js`
    EMOJI_VERSION = 4

    # Return a Pathname to emoji's current versioned folder
    #
    # @return [Pathname] Absolute Path to versioned emojis folder in `public`
    def emoji_public_absolute_path
      Rails.root.join("public/-/emojis/#{EMOJI_VERSION}")
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

    def custom_emoji_tag(name, image_source, render_image: false)
      data = {
        name: name,
        fallback_src: image_source,
        unicode_version: 'custom' # Prevents frontend to check for Unicode support
      }
      options = { title: name, data: data }
      content = render_image ? custom_emoji_image_tag(name, image_source) : ""

      ActionController::Base.helpers.content_tag('gl-emoji', content, options)
    end

    def custom_emoji_image_tag(name, image_source)
      ActionController::Base.helpers.tag.img(
        class: 'emoji', src: image_source, alt: ":#{name}:", title: ":#{name}:", height: 20, align: 'absmiddle'
      )
    end
  end
end
