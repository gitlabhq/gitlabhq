class IntegrationsController < ApplicationController
  respond_to :json

  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  def trigger
    triggered_service = service(integration, params[:command])

    if triggered_service
      render json: triggered_service.new(project, nil, params).execute
    else
      render json: no_integration_found
    end
  end

  private

  def no_integration_found
    {
      response_type: :ephemeral,
      text: 'This slash command has not been registered yet.',
    }
  end

  def integration
    @integration ||= Integration.find_by(external_token: params[:token])
  end

  def project
    integration.project
  end

  def service(integration, command)
    return nil unless integration

    if command == '/issue' && project.issues_enabled? && project.default_issues_tracker?
      Integrations::IssueService
    elsif command == '/merge-request' && project.merge_requests_enabled?
      Integrations::MergeRequestService
    elsif command == '/pipeline' && project.builds_enabled?
      Integrations::PipelineService
    elsif command == '/snippet' && project.snippets_enabled?
      Integrations::ProjectSnippetService
    end
  end
end
