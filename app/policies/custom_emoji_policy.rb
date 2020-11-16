# frozen_string_literal: true

class CustomEmojiPolicy < BasePolicy
  delegate { @subject.group }
end
