class IntegrationsController < ApplicationController
  respond_to :json

  skip_before_filter :verify_authenticity_token
  skip_before_action :authenticate_user!

  before_action :integration

  def trigger
    service = service(params[:command])

    if integration && service
      render json: service.new(project, nil, params).execute
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

  def service(command)
    case command
    when '/issue'
      Integrations::IssueService
    when '/merge_request'
      Integrations::MergeRequestService
    when '/environment'
      Integrations::EnvironmentService
    when '/snippet'
      Integrations::ProjectSnippetService
    end
  end
end
