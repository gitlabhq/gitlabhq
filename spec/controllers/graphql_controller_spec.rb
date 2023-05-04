# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GraphqlController, feature_category: :integrations do
  include GraphqlHelpers

  # two days is enough to make timezones irrelevant
  let_it_be(:last_activity_on) { 2.days.ago.to_date }

  describe 'rescue_from' do
    let_it_be(:message) { 'green ideas sleep furiously' }

    it 'handles ArgumentError' do
      allow(subject).to receive(:execute) do
        raise Gitlab::Graphql::Errors::ArgumentError, message
      end

      post :execute

      expect(json_response).to include(
        'errors' => include(a_hash_including('message' => message))
      )
    end

    it 'handles a timeout nicely' do
      allow(subject).to receive(:execute) do
        raise ActiveRecord::QueryCanceled, '**taps wristwatch**'
      end

      post :execute

      expect(json_response).to include(
        'errors' => include(a_hash_including('message' => /Request timed out/))
      )
    end

    it 'handles StandardError' do
      allow(subject).to receive(:execute) do
        raise StandardError, message
      end

      post :execute

      expect(json_response).to include(
        'errors' => include(
          a_hash_including('message' => /Internal server error/, 'raisedAt' => /graphql_controller_spec.rb/)
        )
      )
    end

    it 'handles Gitlab::Auth::TooManyIps', :aggregate_failures do
      allow(controller).to receive(:execute) do
        raise Gitlab::Auth::TooManyIps.new(150, '123.123.123.123', 10)
      end

      expect(controller).to receive(:log_exception).and_call_original

      post :execute

      expect(json_response).to include(
        'errors' => include(
          a_hash_including('message' => 'User 150 from IP: 123.123.123.123 tried logging from too many ips: 10')
        )
      )
      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'handles Gitlab::Git::ResourceExhaustedError', :aggregate_failures do
      allow(controller).to receive(:execute) do
        raise Gitlab::Git::ResourceExhaustedError.new("Upstream Gitaly has been exhausted. Try again later", 50)
      end

      post :execute

      expect(json_response).to include(
        'errors' => include(
          a_hash_including('message' => 'Upstream Gitaly has been exhausted. Try again later')
        )
      )
      expect(response).to have_gitlab_http_status(:too_many_requests)
      expect(response.headers['Retry-After']).to be(50)
    end
  end

  describe 'POST #execute' do
    context 'when user is logged in' do
      let(:user) { create(:user, last_activity_on: last_activity_on) }

      before do
        sign_in(user)
      end

      it 'sets feature category in ApplicationContext from request' do
        request.headers["HTTP_X_GITLAB_FEATURE_CATEGORY"] = "web_ide"

        post :execute

        expect(::Gitlab::ApplicationContext.current_context_attribute(:feature_category)).to eq('web_ide')
      end

      it 'returns 200 when user can access API' do
        post :execute

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'executes a simple query with no errors' do
        post :execute, params: { query: '{ __typename }' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ 'data' => { '__typename' => 'Query' } })
      end

      it 'executes a simple multiplexed query with no errors' do
        multiplex = [{ query: '{ __typename }' }] * 2

        post :execute, params: { _json: multiplex }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq(
          [
            { 'data' => { '__typename' => 'Query' } },
            { 'data' => { '__typename' => 'Query' } }
          ])
      end

      it 'executes a multiplexed queries with variables with no errors' do
        query = <<~GQL
          mutation($a: String!, $b: String!) {
            echoCreate(input: { messages: [$a, $b] }) { echoes }
          }
        GQL
        multiplex = [
          { query: query, variables: { a: 'A', b: 'B' } },
          { query: query, variables: { a: 'a', b: 'b' } }
        ]

        post :execute, params: { _json: multiplex }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq(
          [
            { 'data' => { 'echoCreate' => { 'echoes' => %w[A B] } } },
            { 'data' => { 'echoCreate' => { 'echoes' => %w[a b] } } }
          ])
      end

      it 'does not allow string as _json parameter' do
        post :execute, params: { _json: 'bad' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({
          "errors" => [
            {
              "message" => "Unexpected end of document",
              "locations" => []
            }
          ]
        })
      end

      it 'sets a limit on the total query size' do
        graphql_query = "{#{(['__typename'] * 1000).join(' ')}}"

        post :execute, params: { query: graphql_query }

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response).to eq({ 'errors' => [{ 'message' => 'Query too large' }] })
      end

      it 'sets a limit on the total query size for multiplex queries' do
        graphql_query = "{#{(['__typename'] * 200).join(' ')}}"
        multiplex = [{ query: graphql_query }] * 5

        post :execute, params: { _json: multiplex }

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response).to eq({ 'errors' => [{ 'message' => 'Query too large' }] })
      end

      it 'returns forbidden when user cannot access API' do
        # User cannot access API in a couple of cases
        # * When user is internal(like ghost users)
        # * When user is blocked
        expect(Ability).to receive(:allowed?).with(user, :log_in, :global).and_call_original
        expect(Ability).to receive(:allowed?).with(user, :access_api, :global).and_return(false)

        post :execute

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response).to include(
          'errors' => include(a_hash_including('message' => /API not accessible/))
        )
      end

      it 'updates the users last_activity_on field' do
        expect { post :execute }.to change { user.reload.last_activity_on }
      end

      it "sets context's sessionless value as false" do
        post :execute

        expect(assigns(:context)[:is_sessionless_user]).to be false
      end

      it 'calls the track api when trackable method' do
        agent = 'vs-code-gitlab-workflow/3.11.1 VSCode/1.52.1 Node.js/12.14.1 (darwin; x64)'
        request.env['HTTP_USER_AGENT'] = agent

        expect(Gitlab::UsageDataCounters::VSCodeExtensionActivityUniqueCounter)
          .to receive(:track_api_request_when_trackable).with(user_agent: agent, user: user)

        post :execute
      end

      it 'calls the track jetbrains api when trackable method' do
        agent = 'gitlab-jetbrains-plugin/0.0.1 intellij-idea/2021.2.4 java/11.0.13 mac-os-x/aarch64/12.1'
        request.env['HTTP_USER_AGENT'] = agent

        expect(Gitlab::UsageDataCounters::JetBrainsPluginActivityUniqueCounter)
          .to receive(:track_api_request_when_trackable).with(user_agent: agent, user: user)

        post :execute
      end

      context 'if using the GitLab CLI' do
        it 'call trackable for the old UserAgent' do
          agent = 'GLab - GitLab CLI'

          request.env['HTTP_USER_AGENT'] = agent

          expect(Gitlab::UsageDataCounters::GitLabCliActivityUniqueCounter)
            .to receive(:track_api_request_when_trackable).with(user_agent: agent, user: user)

          post :execute
        end

        it 'call trackable for the current UserAgent' do
          agent = 'glab/v1.25.3-27-g7ec258fb (built 2023-02-16), darwin'

          request.env['HTTP_USER_AGENT'] = agent

          expect(Gitlab::UsageDataCounters::GitLabCliActivityUniqueCounter)
            .to receive(:track_api_request_when_trackable).with(user_agent: agent, user: user)

          post :execute
        end
      end

      it "assigns username in ApplicationContext" do
        post :execute

        expect(Gitlab::ApplicationContext.current).to include('meta.user' => user.username)
      end
    end

    context 'when 2FA is required for the user' do
      let(:user) { create(:user, last_activity_on: last_activity_on) }

      before do
        group = create(:group, require_two_factor_authentication: true)
        group.add_developer(user)

        sign_in(user)
      end

      it 'does not redirect if 2FA is enabled' do
        expect(controller).not_to receive(:redirect_to)

        post :execute

        expect(response).to have_gitlab_http_status(:unauthorized)

        expected_message = "Authentication error: " \
        "enable 2FA in your profile settings to continue using GitLab: %{mfa_help_page}" %
          { mfa_help_page: controller.mfa_help_page_url }

        expect(json_response).to eq({ 'errors' => [{ 'message' => expected_message }] })
      end
    end

    context 'when user uses an API token' do
      let(:user) { create(:user, last_activity_on: last_activity_on) }
      let(:token) { create(:personal_access_token, user: user, scopes: [:api]) }
      let(:query) { '{ __typename }' }

      subject { post :execute, params: { query: query, access_token: token.token } }

      context 'when the user is a project bot' do
        let(:user) { create(:user, :project_bot, last_activity_on: last_activity_on) }

        it 'updates the users last_activity_on field' do
          expect { subject }.to change { user.reload.last_activity_on }
        end

        it "sets context's sessionless value as true" do
          subject

          expect(assigns(:context)[:is_sessionless_user]).to be true
        end

        it 'executes a simple query with no errors' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq({ 'data' => { '__typename' => 'Query' } })
        end

        it 'can access resources the project_bot has access to' do
          project_a, project_b = create_list(:project, 2, :private)
          project_a.add_developer(user)

          post :execute, params: { query: <<~GQL, access_token: token.token }
            query {
              a: project(fullPath: "#{project_a.full_path}") { name }
              b: project(fullPath: "#{project_b.full_path}") { name }
            }
          GQL

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq({ 'data' => { 'a' => { 'name' => project_a.name }, 'b' => nil } })
        end
      end

      it 'updates the users last_activity_on field' do
        expect { subject }.to change { user.reload.last_activity_on }
      end

      it "sets context's sessionless value as true" do
        subject

        expect(assigns(:context)[:is_sessionless_user]).to be true
      end

      it "assigns username in ApplicationContext" do
        subject

        expect(Gitlab::ApplicationContext.current).to include('meta.user' => user.username)
      end

      it 'calls the track api when trackable method' do
        agent = 'vs-code-gitlab-workflow/3.11.1 VSCode/1.52.1 Node.js/12.14.1 (darwin; x64)'
        request.env['HTTP_USER_AGENT'] = agent

        expect(Gitlab::UsageDataCounters::VSCodeExtensionActivityUniqueCounter)
          .to receive(:track_api_request_when_trackable).with(user_agent: agent, user: user)

        subject
      end

      it 'calls the track jetbrains api when trackable method' do
        agent = 'gitlab-jetbrains-plugin/0.0.1 intellij-idea/2021.2.4 java/11.0.13 mac-os-x/aarch64/12.1'
        request.env['HTTP_USER_AGENT'] = agent

        expect(Gitlab::UsageDataCounters::JetBrainsPluginActivityUniqueCounter)
          .to receive(:track_api_request_when_trackable).with(user_agent: agent, user: user)

        subject
      end

      it 'calls the track gitlab cli when trackable method' do
        agent = 'GLab - GitLab CLI'
        request.env['HTTP_USER_AGENT'] = agent

        expect(Gitlab::UsageDataCounters::GitLabCliActivityUniqueCounter)
          .to receive(:track_api_request_when_trackable).with(user_agent: agent, user: user)

        subject
      end
    end

    context 'when user is not logged in' do
      it 'returns 200' do
        post :execute

        expect(response).to have_gitlab_http_status(:ok)
      end

      it "sets context's sessionless value as false" do
        post :execute

        expect(assigns(:context)[:is_sessionless_user]).to be false
      end

      it "does not assign a username in ApplicationContext" do
        subject

        expect(Gitlab::ApplicationContext.current.key?('meta.user')).to be false
      end
    end

    it 'includes request object in context' do
      post :execute

      expect(assigns(:context)[:request]).to eq request
    end

    it 'sets `context[:remove_deprecated]` to false by default' do
      post :execute

      expect(assigns(:context)[:remove_deprecated]).to be false
    end

    it 'sets `context[:remove_deprecated]` to true when `remove_deprecated` param is truthy' do
      post :execute, params: { remove_deprecated: '1' }

      expect(assigns(:context)[:remove_deprecated]).to be true
    end
  end

  describe 'Admin Mode' do
    let_it_be(:admin) { create(:admin) }
    let_it_be(:project) { create(:project) }

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

  describe '#append_info_to_payload' do
    let(:query_1) { { query: graphql_query_for('project', { 'fullPath' => 'foo' }, %w(id name), 'getProject_1') } }
    let(:query_2) { { query: graphql_query_for('project', { 'fullPath' => 'bar' }, %w(id), 'getProject_2') } }
    let(:graphql_queries) { [query_1, query_2] }
    let(:log_payload) { {} }
    let(:expected_logs) do
      [
        {
          operation_name: 'getProject_1',
          complexity: 3,
          depth: 2,
          used_deprecated_fields: [],
          used_fields: ['Project.id', 'Project.name', 'Query.project'],
          variables: '{}'
        },
        {
          operation_name: 'getProject_2',
          complexity: 2,
          depth: 2,
          used_deprecated_fields: [],
          used_fields: ['Project.id', 'Query.project'],
          variables: '{}'
        }
      ]
    end

    before do
      RequestStore.clear!

      allow(controller).to receive(:append_info_to_payload).and_wrap_original do |method, *|
        method.call(log_payload)
      end
    end

    it 'appends metadata for logging' do
      post :execute, params: { _json: graphql_queries }

      expect(controller).to have_received(:append_info_to_payload)
      expect(log_payload.dig(:metadata, :graphql)).to match_array(expected_logs)
    end

    it 'appends the exception in case of errors' do
      exception = StandardError.new('boom')

      expect(controller).to receive(:execute).and_raise(exception)

      post :execute, params: { _json: graphql_queries }

      expect(controller).to have_received(:append_info_to_payload)
      expect(log_payload.dig(:exception_object)).to eq(exception)
    end
  end
end
