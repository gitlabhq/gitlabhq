# frozen_string_literal: true

module Impersonation
  include Gitlab::Utils::StrongMemoize

  def current_user
    user = super

    user.impersonator = impersonator if impersonator

    user
  end

  protected

  def check_impersonation_availability
    return unless session[:impersonator_id]

    unless Gitlab.config.gitlab.impersonation_enabled
      stop_impersonation
      access_denied! _('Impersonation has been disabled')
    end
  end

  def stop_impersonation
    log_impersonation_event

    warden.set_user(impersonator, scope: :user)
    session[:impersonator_id] = nil

    current_user
  end

  def log_impersonation_event
    Gitlab::AppLogger.info("User #{impersonator.username} has stopped impersonating #{current_user.username}")
  end

  def impersonator
    strong_memoize(:impersonator) do
      User.find(session[:impersonator_id]) if session[:impersonator_id]
    end
  end
end
