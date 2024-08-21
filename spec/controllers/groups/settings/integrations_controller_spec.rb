# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Settings::IntegrationsController, feature_category: :integrations do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    stub_feature_flags(remove_monitor_metrics: false)
    sign_in(user)
  end

  it_behaves_like Integrations::Actions do
    let(:integration_attributes) { { group: group, project: nil } }

    let(:routing_params) do
      {
        group_id: group,
        id: integration.to_param
      }
    end

    before do
      group.add_owner(user)
    end
  end

  describe '#index' do
    context 'when user is not owner' do
      it 'renders not_found' do
        get :index, params: { group_id: group }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is owner' do
      before do
        group.add_owner(user)
      end

      it 'successfully displays the template' do
        get :index, params: { group_id: group }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:index)
      end
    end
  end

  describe '#edit' do
    context 'when user is not owner' do
      it 'renders not_found' do
        get :edit,
          params: {
            group_id: group,
            id: Integration.available_integration_names(
              include_project_specific: false, include_instance_specific: false
            ).sample
          }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is owner' do
      before do
        group.add_owner(user)
      end

      Integration.available_integration_names(
        include_project_specific: false, include_instance_specific: false
      ).each do |integration_name|
        context integration_name do
          it 'successfully displays the template' do
            get :edit, params: { group_id: group, id: integration_name }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template(:edit)
          end
        end
      end
    end
  end

  describe '#update' do
    include JiraIntegrationHelpers

    let(:integration) { create(:jira_integration, :group, group: group) }

    before do
      group.add_owner(user)
      stub_jira_integration_test

      put :update, params: { group_id: group, id: integration.class.to_param, service: params }
    end

    context 'with valid params' do
      let(:params) { { url: 'https://jira.gitlab-example.com', password: 'password' } }

      it 'updates the integration' do
        expect(response).to have_gitlab_http_status(:found)
        expect(integration.reload).to have_attributes(params)
      end
    end

    context 'with invalid params' do
      let(:params) { { url: 'invalid', password: 'password' } }

      it 'does not update the integration' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:edit)
        expect(integration.reload).not_to have_attributes(params)
      end
    end
  end

  describe '#reset' do
    let_it_be(:integration) { create(:jira_integration, :group, group: group) }
    let_it_be(:inheriting_integration) { create(:jira_integration, inherit_from_id: integration.id) }

    subject do
      post :reset, params: { group_id: group, id: integration.class.to_param }
    end

    context 'when user is not owner' do
      it 'renders not_found' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is owner' do
      before do
        group.add_owner(user)
      end

      it 'returns 200 OK', :aggregate_failures do
        subject

        expected_json = {}.to_json

        expect(flash[:notice]).to eq('This integration, and inheriting projects were reset.')
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to eq(expected_json)
      end

      it 'deletes the integration and all inheriting integrations' do
        expect { subject }.to change { Integrations::Jira.for_group(group.id).count }.by(-1)
          .and change { Integrations::Jira.inherit_from_id(integration.id).count }.by(-1)
      end

      context 'when integration does not allow manual activation' do
        let_it_be(:integration) do
          create(:gitlab_slack_application_integration, :group, group: group,
            slack_integration: build(:slack_integration)
          )
        end

        it 'renders unprocessable_entity' do
          stub_application_setting(slack_app_enabled: true)

          subject

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(response.body).to eq({ message: 'Integration cannot be reset.' }.to_json)
        end
      end
    end
  end
end
