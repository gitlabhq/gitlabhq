# frozen_string_literal: true

class CustomEmojiPolicy < BasePolicy
  delegate { @subject.group }

  condition(:author) { @subject.creator == @user }

  rule { can?(:maintainer_access) }.policy do
    enable :delete_custom_emoji
  end

  rule { author & can?(:create_custom_emoji) }.policy do
    enable :delete_custom_emoji
  end
end
