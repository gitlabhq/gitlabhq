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

  def self.normilize_emoji_name(name)
    aliases[name] || name
  end

  def self.emoji_by_category
    unless @emoji_by_category
      @emoji_by_category = {}

      emojis.each do |emoji_name, data|
        data["name"] = emoji_name

        @emoji_by_category[data["category"]] ||= []
        @emoji_by_category[data["category"]] << data
      end

      @emoji_by_category = @emoji_by_category.sort.to_h
    end

    @emoji_by_category
  end

  def self.emojis
    @emojis ||= begin
      json_path = File.join(Rails.root, 'fixtures', 'emojis', 'index.json' )
      JSON.parse(File.read(json_path))
    end
  end

  def self.aliases
    @aliases ||= begin
      json_path = File.join(Rails.root, 'fixtures', 'emojis', 'aliases.json' )
      JSON.parse(File.read(json_path))
    end
  end
end
