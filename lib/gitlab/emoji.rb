# frozen_string_literal: true

module Gitlab
  module Emoji
    extend self

    def emojis
      Gemojione.index.instance_variable_get(:@emoji_by_name)
    end

    def emojis_by_moji
      Gemojione.index.instance_variable_get(:@emoji_by_moji)
    end

    def emojis_unicodes
      emojis_by_moji.keys
    end

    def emojis_names
      emojis.keys
    end

    def emojis_aliases
      @emoji_aliases ||= Gitlab::Json.parse(File.read(Rails.root.join('fixtures', 'emojis', 'aliases.json')))
    end

    def emoji_filename(name)
      emojis[name]["unicode"]
    end

    def emoji_unicode_filename(moji)
      emojis_by_moji[moji]["unicode"]
    end

    def emoji_unicode_version(name)
      emoji_unicode_versions_by_name[name]
    end

    def normalize_emoji_name(name)
      emojis_aliases[name] || name
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

    def emoji_exists?(name)
      emojis.has_key?(name)
    end

    # CSS sprite fallback takes precedence over image fallback
    def gl_emoji_tag(name, options = {})
      emoji_name = emojis_aliases[name] || name
      emoji_info = emojis[emoji_name]
      return unless emoji_info

      data = {
        name: emoji_name,
        unicode_version: emoji_unicode_version(emoji_name)
      }
      options = { title: emoji_info['description'], data: data }.merge(options)

      ActionController::Base.helpers.content_tag('gl-emoji', emoji_info['moji'], options)
    end

    def custom_emoji_tag(name, image_source)
      data = {
        name: name
      }

      ActionController::Base.helpers.content_tag('gl-emoji', title: name, data: data) do
        emoji_image_tag(name, image_source).html_safe
      end
    end

    private

    def emoji_unicode_versions_by_name
      @emoji_unicode_versions_by_name ||=
        Gitlab::Json.parse(File.read(Rails.root.join('fixtures', 'emojis', 'emoji-unicode-version-map.json')))
    end
  end
end
