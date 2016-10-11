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
      emojis_by_moji.keys.sort
    end
    def emojis_names
      emojis.keys.sort
    end

    def emoji_filename(name)
      emojis[name]["unicode"]
    end
    def emoji_unicode_filename(moji)
      emojis_by_moji[moji]["unicode"]
    end
  end
end
