# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Settings::RepositoryController do
  include ExternalAuthorizationServiceHelpers

  let(:group) { create(:group) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'POST create_deploy_token' do
    context 'when ajax_new_deploy_token feature flag is disabled for the project' do
      before do
        stub_feature_flags(ajax_new_deploy_token: false)
        entity.add_owner(user)
      end

      it_behaves_like 'a created deploy token' do
        let(:entity) { group }
        let(:create_entity_params) { { group_id: group } }
        let(:deploy_token_type) { DeployToken.deploy_token_types[:group_type] }
      end
    end

    context 'when ajax_new_deploy_token feature flag is enabled for the project' do
      let(:good_deploy_token_params) do
        {
          name: 'name',
          expires_at: 1.day.from_now.to_s,
          username: 'deployer',
          read_repository: '1',
          deploy_token_type: DeployToken.deploy_token_types[:group_type]
        }
      end

      let(:request_params) do
        {
          group_id: group.to_param,
          deploy_token: deploy_token_params
        }
      end

      before do
        group.add_owner(user)
      end

      subject { post :create_deploy_token, params: request_params, format: :json }

      context('a good request') do
        let(:deploy_token_params) { good_deploy_token_params }
        let(:expected_response) do
          {
            'id' => be_a(Integer),
            'name' => deploy_token_params[:name],
            'username' => deploy_token_params[:username],
            'expires_at' => Time.zone.parse(deploy_token_params[:expires_at]),
            'token' => be_a(String),
            'expired' => false,
            'revoked' => false,
            'scopes' => deploy_token_params.inject([]) do |scopes, kv|
              key, value = kv
              key.to_s.start_with?('read_') && value.to_i != 0 ? scopes << key.to_s : scopes
            end
          }
        end

        it 'creates the deploy token' do
          subject

          expect(response).to have_gitlab_http_status(:created)
          expect(response).to match_response_schema('public_api/v4/deploy_token')
          expect(json_response).to match(expected_response)
        end
      end

      context('a bad request') do
        let(:deploy_token_params) { good_deploy_token_params.except(:read_repository) }
        let(:expected_response) { { 'message' => "Scopes can't be blank" } }

        it 'does not create the deploy token' do
          subject

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response).to match(expected_response)
        end
      end

      context('an invalid request') do
        let(:deploy_token_params) { good_deploy_token_params.except(:name) }

        it 'raises a validation error' do
          expect { subject }.to raise_error(ActiveRecord::StatementInvalid)
        end
      end
    end
  end
end
