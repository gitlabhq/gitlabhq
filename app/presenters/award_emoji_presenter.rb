# frozen_string_literal: true

class AwardEmojiPresenter < Gitlab::View::Presenter::Delegated
  presents ::AwardEmoji, as: :award_emoji

  def description
    as_emoji&.description
  end

  def unicode
    as_emoji&.hex
  end

  def emoji
    as_emoji&.codepoints
  end

  def unicode_version
    as_emoji&.unicode_version
  end

  private

  def as_emoji
    @emoji ||= TanukiEmoji.find_by_alpha_code(award_emoji.name)
  end
end
