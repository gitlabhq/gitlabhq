module Gitlab
  class AwardEmoji
    CATEGORIES = {
      other: "Other",
      objects: "Objects",
      places: "Places",
      travel_places: "Travel",
      emoticons: "Emoticons",
      objects_symbols: "Symbols",
      nature: "Nature",
      celebration: "Celebration",
      people: "People",
      activity: "Activity",
      flags: "Flags",
      food_drink: "Food"
    }.with_indifferent_access

    CATEGORY_ALIASES = {
      symbols: "objects_symbols",
      foods: "food_drink",
      travel: "travel_places"
    }.with_indifferent_access

    def self.normalize_emoji_name(name)
      aliases[name] || name
    end

    def self.emoji_by_category
      unless @emoji_by_category
        @emoji_by_category = Hash.new { |h, key| h[key] = [] }

        emojis.each do |emoji_name, data|
          data["name"] = emoji_name

          # Skip Fitzpatrick(tone) modifiers
          next if data["category"] == "modifier"

          category = CATEGORY_ALIASES[data["category"]] || data["category"]

          @emoji_by_category[category] << data
        end

        @emoji_by_category = @emoji_by_category.sort.to_h
      end

      @emoji_by_category
    end

    def self.emojis
      @emojis ||=
        begin
          json_path = File.join(Rails.root, 'fixtures', 'emojis', 'index.json' )
          JSON.parse(File.read(json_path))
        end
    end

    def self.aliases
      @aliases ||=
        begin
         json_path = File.join(Rails.root, 'fixtures', 'emojis', 'aliases.json' )
         JSON.parse(File.read(json_path))
       end
    end

    # Returns an Array of Emoji names and their asset URLs.
    def self.urls
      @urls ||= begin
                  path = File.join(Rails.root, 'fixtures', 'emojis', 'digests.json')
                  # Construct the full asset path ourselves because
                  # ActionView::Helpers::AssetUrlHelper.asset_url is slow for hundreds
                  # of entries since it has to do a lot of extra work (e.g. regexps).
                  prefix = Gitlab::Application.config.assets.prefix
                  digest = Gitlab::Application.config.assets.digest
                  base =
                    if defined?(Gitlab::Application.config.relative_url_root) && Gitlab::Application.config.relative_url_root
                      Gitlab::Application.config.relative_url_root
                    else
                      ''
                    end

                  JSON.parse(File.read(path)).map do |hash|
                    if digest
                      fname = "#{hash['unicode']}-#{hash['digest']}"
                    else
                      fname = hash['unicode']
                    end

                    { name: hash['name'], path: File.join(base, prefix, "#{fname}.png") }
                  end
                end
    end
  end
end
