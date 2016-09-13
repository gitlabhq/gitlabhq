require 'rails_helper'

RSpec.describe IntegrationsController, type: :controller do
  describe 'POST trigger' do
    context 'when Slack triggers a request' do
      let(:slack_params) do
        {
          format: :json,
          "token"=>"24randomcharacters",
          "team_id"=>"T123456T9",
          "team_domain"=>"mepmep",
          "channel_id"=>"C12345678",
          "channel_name"=>"general",
          "user_id"=>"U12345678",
          "user_name"=>"mep",
          "command"=>"/issue",
          "text"=>"3",
          "response_url"=>"https://hooks.slack.com/commands/T123456T9/79958163905/siWqY7Qtx8z0zWFsXBod9VEy"
        }
      end

      let(:json_response) { JSON.parse(response.body) }

      it 'returns a 200 status code' do
        post :trigger, slack_params

        expect(response).to have_http_status(200)
        expect(json_response['response_type']).to eq 'ephemeral'
        expect(json_response['text']).to eq 'This slash command has not been registered yet.'
      end

      context 'when the integration is registered' do
        let!(:slack_integration) { create(:integration) }
        let(:issue) { create(:issue, project: slack_integration.project) }

        describe 'lookup issue on ID' do
          it 'returns the wanted resource' do
            slack_params["token"] = slack_integration.external_token
            slack_params['text'] = issue.iid

            post :trigger, slack_params

            expect(response).to have_http_status(200)
            expect(json_response['response_type']).to eq 'in_channel'
            expect(json_response['text']).to match /#\d+\s#{Regexp.quote(issue.title)}/
          end
        end
      end
    end
  end
end
