# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::BranchesController, feature_category: :integrations do
  describe '#new' do
    context 'when logged in' do
      let_it_be(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it 'assigns the suggested branch name' do
        get :new, params: { issue_key: 'ACME-123', issue_summary: 'My Issue !@#$%' }

        expect(response).to be_successful
        expect(assigns(:new_branch_data)).to include(
          initial_branch_name: 'ACME-123-my-issue',
          success_state_svg_path: start_with('/assets/illustrations/empty-state/empty-merge-requests-md-')
        )
      end

      it 'ignores missing summary' do
        get :new, params: { issue_key: 'ACME-123' }

        expect(response).to be_successful
        expect(assigns(:new_branch_data)).to include(initial_branch_name: 'ACME-123')
      end

      it 'does not set a branch name if key is not passed' do
        get :new, params: { issue_summary: 'My issue' }

        expect(response).to be_successful
        expect(assigns(:new_branch_data)).to include('initial_branch_name': nil)
      end
    end

    context 'when not logged in' do
      it 'redirects to the login page' do
        get :new

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe '#route' do
    let(:addonkey) { 'app_key' }
    let(:params) { { issue_key: 'ACME-123', issue_summary: 'My Issue !@#$%', jwt: jwt, addonkey: addonkey } }

    context 'without a valid jwt' do
      let(:jwt) { nil }

      it 'returns 403' do
        get :route, params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with a valid jwt' do
      let_it_be(:installation) { create(:jira_connect_installation, instance_url: 'https://self-managed.gitlab.io') }
      let(:qsh) { Atlassian::Jwt.create_query_string_hash('https://gitlab.test/subscriptions', 'GET', 'https://gitlab.test') }
      let(:jwt) { Atlassian::Jwt.encode({ iss: installation.client_key, qsh: qsh }, installation.shared_secret) }
      let(:symmetric_jwt) { Atlassian::JiraConnect::Jwt::Symmetric.new(jwt) }
      let(:query_string) { URI.encode_www_form(params.sort.to_h) }

      before do
        allow(Atlassian::JiraConnect::Jwt::Symmetric).to receive(:route).with(params[:jwt]).and_return(symmetric_jwt)
      end

      context 'when the jira installation is not for a self-managed instance' do
        let_it_be(:installation) { create(:jira_connect_installation) }

        it 'redirects to :new' do
          get :route, params: params
          expect(response).to redirect_to("#{new_jira_connect_branch_url}?#{query_string}")
        end
      end

      context 'when the jira installation is for a self-managed instance' do
        let(:create_branch_url) do
          Gitlab::Utils.append_path(installation.instance_url, new_jira_connect_branch_path)
        end

        it 'redirects to the self-managed installation' do
          get :route, params: params
          expect(response).to redirect_to("#{create_branch_url}?#{query_string}")
        end
      end
    end
  end
end
