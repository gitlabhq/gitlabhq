# frozen_string_literal: true

module Impersonation
  include Gitlab::Utils::StrongMemoize

  SESSION_KEYS_TO_DELETE = %w[
    github_access_token gitea_access_token gitlab_access_token
    bitbucket_token bitbucket_refresh_token bitbucket_server_personal_access_token
    bulk_import_gitlab_access_token fogbugz_token cloud_platform_access_token
  ].freeze

  def current_user
    user = super

    user.impersonator = impersonator if impersonator

    user
  end

  protected

  def check_impersonation_availability
    return unless impersonation_in_progress?

    unless Gitlab.config.gitlab.impersonation_enabled
      stop_impersonation
      access_denied! _('Impersonation has been disabled')
    end
  end

  def stop_impersonation
    log_impersonation_event

    warden.set_user(impersonator, scope: :user)
    session[:impersonator_id] = nil
    clear_access_token_session_keys!

    current_user
  end

  def impersonation_in_progress?
    session[:impersonator_id].present?
  end

  def log_impersonation_event
    Gitlab::AppLogger.info("User #{impersonator.username} has stopped impersonating #{current_user.username}")
  end

  def clear_access_token_session_keys!
    access_tokens_keys = session.keys & SESSION_KEYS_TO_DELETE

    access_tokens_keys.each { |key| session.delete(key) }
  end

  def impersonator
    User.find(session[:impersonator_id]) if session[:impersonator_id]
  end
  strong_memoize_attr :impersonator
end
