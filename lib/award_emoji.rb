class AwardEmoji
  EMOJI_LIST = [
    "+1", "-1", "100", "blush", "heart", "smile", "rage",
    "beers", "disappointed", "ok_hand",
    "helicopter", "shit", "airplane", "alarm_clock",
    "ambulance", "anguished", "two_hearts", "wink"
  ]

  def self.path_to_emoji_image(name)
    "emoji/#{Emoji.emoji_filename(name)}.png"
  end
end
