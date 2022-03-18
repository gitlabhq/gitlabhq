# frozen_string_literal: true

module Users
  class SavedReplyPolicy < BasePolicy
    delegate { @subject.user }
  end
end
