# frozen_string_literal: true

module InitializesCurrentUserMode
  extend ActiveSupport::Concern

  included do
    helper_method :current_user_mode
  end

  def current_user_mode
    @current_user_mode ||= Gitlab::Auth::CurrentUserMode.new(current_user)
  end
end
