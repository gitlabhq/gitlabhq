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
      @emoji_aliases ||= JSON.parse(File.read(Rails.root.join('fixtures', 'emojis', 'aliases.json')))
    end

    def emoji_filename(name)
      emojis[name]["unicode"]
    end

    def emoji_unicode_filename(moji)
      emojis_by_moji[moji]["unicode"]
    end

    def emoji_unicode_version(name)
      @emoji_unicode_versions_by_name ||= JSON.parse(File.read(Rails.root.join('fixtures', 'emojis', 'emoji-unicode-version-map.json')))
      @emoji_unicode_versions_by_name[name]
    end

    def normalize_emoji_name(name)
      emojis_aliases[name] || name
    end

    def emoji_image_tag(name, src)
      "<img class='emoji' title=':#{name}:' alt=':#{name}:' src='#{src}' height='20' width='20' align='absmiddle' />"
    end

    # CSS sprite fallback takes precedence over image fallback
    def gl_emoji_tag(name, image: false, sprite: false, force_fallback: false)
      emoji_name = emojis_aliases[name] || name
      emoji_info = emojis[emoji_name]
      emoji_fallback_image_source = ActionController::Base.helpers.url_to_image("emoji/#{emoji_info['name']}.png")
      emoji_fallback_sprite_class = "emoji-#{emoji_name}"

      data = {
        name: emoji_name,
        unicode_version: emoji_unicode_version(emoji_name)
      }
      data[:fallback_src] = emoji_fallback_image_source if image
      data[:fallback_sprite_class] = emoji_fallback_sprite_class if sprite
      ActionController::Base.helpers.content_tag 'gl-emoji',
        class: ("emoji-icon #{emoji_fallback_sprite_class}" if force_fallback && sprite),
        data: data do
        if force_fallback && !sprite
          emoji_image_tag(emoji_name, emoji_fallback_image_source)
        else
          emoji_info['moji']
        end
      end
    end
  end
end
