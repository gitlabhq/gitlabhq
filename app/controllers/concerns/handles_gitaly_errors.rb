# frozen_string_literal: true

module HandlesGitalyErrors
  extend ActiveSupport::Concern

  GITALY_ERRORS = [
    Gitlab::Git::CommandError,
    Gitlab::Git::CommandTimedOut,
    GRPC::Unavailable,
    GRPC::ResourceExhausted,
    Gitlab::Git::ResourceExhaustedError,
    GRPC::DeadlineExceeded
  ].freeze

  included do
    rescue_from(*GITALY_ERRORS, with: :handle_gitaly_error)
  end

  private

  # rubocop:disable Gitlab/ModuleWithInstanceVariables -- Allows us to pass gitaly availability to frontend
  def handle_gitaly_error(exception)
    Gitlab::ErrorTracking.track_exception(exception)

    @gitaly_unavailable = true

    respond_to do |format|
      format.html { render action: action_name, status: :service_unavailable }
      format.json { render json: { error: gitaly_unavailable_message }, status: :service_unavailable }
      format.atom { render action: action_name, layout: 'xml', status: :service_unavailable }
      format.any { render plain: gitaly_unavailable_message, status: :service_unavailable }
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def gitaly_unavailable_message
    if Gitlab.com? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- Message differs between SaaS and self-managed
      _('GitLab is currently unable to handle this request. Please try again later.')
    else
      _('The git server, Gitaly, is not available at this time. Please contact your administrator.')
    end
  end
end
