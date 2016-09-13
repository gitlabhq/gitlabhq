class IntegrationsController < ApplicationController
  respond_to :json

  skip_before_filter :verify_authenticity_token
  skip_before_action :authenticate_user!


  def trigger
    render json: slack_response(Issue.last).to_json
  end

  private

  def slack_response(resource)
    {
      response_type: "in_channel",
      text: "#{resource.title}",
      attachments: [
          {
              "text":"#{resource.description}"
          }
      ]
    }
  end
end
