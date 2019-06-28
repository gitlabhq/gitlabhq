# frozen_string_literal: true

class AwardEmojiPresenter < Gitlab::View::Presenter::Delegated
  presents :award_emoji

  def description
    as_emoji['description']
  end

  def unicode
    as_emoji['unicode']
  end

  def emoji
    as_emoji['moji']
  end

  def unicode_version
    Gitlab::Emoji.emoji_unicode_version(award_emoji.name)
  end

  private

  def as_emoji
    @emoji ||= Gitlab::Emoji.emojis[award_emoji.name] || {}
  end
end
