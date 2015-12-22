class AwardEmoji
  ALIASES = {
    pout: "rage",
    satisfied: "laughing",
    hankey: "shit",
    poop: "shit",
    collision: "boom",
    thumbsup: "+1",
    thumbsdown: "-1",
    punch: "facepunch",
    raised_hand: "hand",
    running: "runner",
    ng_woman: "no_good",
    shoe: "mans_shoe",
    tshirt: "shirt",
    honeybee: "bee",
    flipper: "dolphin",
    paw_prints: "feet",
    waxing_gibbous_moon: "moon",
    telephone: "phone",
    knife: "hocho",
    envelope: "email",
    pencil: "memo",
    open_book: "book",
    sailboat: "boat",
    red_car: "car",
    lantern: "izakaya_lantern",
    uk: "gb",
    heavy_exclamation_mark: "exclamation",
    squirrel: "shipit"
  }.with_indifferent_access

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
    ALIASES[name] || name
  end

  def self.emoji_by_category
    unless @emoji_by_category
      @emoji_by_category = {}
      emojis_added = []

      Emoji.emojis.each do |emoji_name, data|
        next if emojis_added.include?(data["name"])
        emojis_added << data["name"]

        @emoji_by_category[data["category"]] ||= []
        @emoji_by_category[data["category"]] << data
      end

      @emoji_by_category = @emoji_by_category.sort.to_h
    end

    @emoji_by_category
  end
end
