class AwardEmoji
  EMOJI_LIST = [
    "+1", "-1", "100", "blush", "heart", "smile", "rage",
    "beers", "disappointed", "ok_hand",
    "helicopter", "shit", "airplane", "alarm_clock",
    "ambulance", "anguished", "two_hearts", "wink"
  ]

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

  def self.path_to_emoji_image(name)
    "emoji/#{Emoji.emoji_filename(name)}.png"
  end

  def self.normilize_emoji_name(name)
    ALIASES[name] || name
  end
end
