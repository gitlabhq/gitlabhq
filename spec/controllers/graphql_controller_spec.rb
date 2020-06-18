# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GraphqlController do
  include GraphqlHelpers

  before do
    stub_feature_flags(graphql: true)
  end

  describe 'ArgumentError' do
    let(:user) { create(:user) }
    let(:message) { 'green ideas sleep furiously' }

    before do
      sign_in(user)
    end

    it 'handles argument errors' do
      allow(subject).to receive(:execute) do
        raise Gitlab::Graphql::Errors::ArgumentError, message
      end

      post :execute

      expect(json_response).to include(
        'errors' => include(a_hash_including('message' => message))
      )
    end
  end

  describe 'POST #execute' do
    context 'when user is logged in' do
      let(:user) { create(:user, last_activity_on: Date.yesterday) }

      before do
        sign_in(user)
      end

      it 'returns 200 when user can access API' do
        post :execute

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns access denied template when user cannot access API' do
        # User cannot access API in a couple of cases
        # * When user is internal(like ghost users)
        # * When user is blocked
        expect(Ability).to receive(:allowed?).with(user, :log_in, :global).and_call_original
        expect(Ability).to receive(:allowed?).with(user, :access_api, :global).and_return(false)

        post :execute

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(response).to render_template('errors/access_denied')
      end

      it 'updates the users last_activity_on field' do
        expect { post :execute }.to change { user.reload.last_activity_on }
      end
    end

    context 'when user uses an API token' do
      let(:user) { create(:user, last_activity_on: Date.yesterday) }
      let(:token) { create(:personal_access_token, user: user, scopes: [:api]) }

      it 'updates the users last_activity_on field' do
        expect { post :execute, params: { access_token: token.token } }.to change { user.reload.last_activity_on }
      end
    end

    context 'when user is not logged in' do
      it 'returns 200' do
        post :execute

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'Admin Mode' do
    let(:admin) { create(:admin) }
    let(:project) { create(:project) }
    let(:graphql_query) { graphql_query_for('project', { 'fullPath' => project.full_path }, %w(id name)) }

    before do
      sign_in(admin)
    end

    context 'when admin mode enabled' do
      before do
        Gitlab::Session.with_session(controller.session) do
          controller.current_user_mode.request_admin_mode!
          controller.current_user_mode.enable_admin_mode!(password: admin.password)
        end
      end

      it 'can query project data' do
        post :execute, params: { query: graphql_query }

        expect(controller.current_user_mode.admin_mode?).to be(true)
        expect(json_response['data']['project']['name']).to eq(project.name)
      end
    end

    context 'when admin mode disabled' do
      it 'cannot query project data' do
        post :execute, params: { query: graphql_query }

        expect(controller.current_user_mode.admin_mode?).to be(false)
        expect(json_response['data']['project']).to be_nil
      end

      context 'when admin is member of the project' do
        before do
          project.add_developer(admin)
        end

        it 'can query project data' do
          post :execute, params: { query: graphql_query }

          expect(controller.current_user_mode.admin_mode?).to be(false)
          expect(json_response['data']['project']['name']).to eq(project.name)
        end
      end
    end
  end
end
