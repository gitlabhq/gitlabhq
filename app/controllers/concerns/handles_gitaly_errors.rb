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
      format.html do
        # Streaming and component-rendering actions have no template for
        # `render action:`, which would turn this 503 into a MissingTemplate 500.
        # Called on lookup_context because some controllers include
        # ApplicationHelper, whose single-argument #template_exists? shadows the
        # Rails one.
        if lookup_context.exists?(action_name, _prefixes) # rubocop:disable CodeReuse/ActiveRecord -- lookup_context is a view lookup, not a model
          render action: action_name, status: :service_unavailable
        else
          render_plain_gitaly_error
        end
      end
      format.json { render json: { error: gitaly_unavailable_message }, status: :service_unavailable }
      format.atom { render action: action_name, layout: 'xml', status: :service_unavailable }
      format.any { render_plain_gitaly_error }
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def render_plain_gitaly_error
    render plain: gitaly_unavailable_message, status: :service_unavailable
  end

  def gitaly_unavailable_message
    if Gitlab.com? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- Message differs between SaaS and self-managed
      _('GitLab is currently unable to handle this request. Please try again later.')
    else
      _('The git server, Gitaly, is not available at this time. Please contact your administrator.')
    end
  end
end
