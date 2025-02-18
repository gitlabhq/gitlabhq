# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GraphqlController, feature_category: :integrations do
  include GraphqlHelpers
  include Auth::DpopTokenHelper

  # two days is enough to make timezones irrelevant
  let_it_be(:last_activity_on) { 2.days.ago.to_date }

  let(:app_context) { Gitlab::ApplicationContext.current }

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
      expect(response).to have_gitlab_http_status(:service_unavailable)
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

      it 'does not allow string as _json parameter (a malformed multiplex query)' do
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

      it 'calls the track jetbrains bundled third party api when trackable method' do
        agent = 'IntelliJ-GitLab-Plugin PhpStorm/PS-232.6734.11 (JRE 17.0.7+7-b966.2; Linux 6.2.0-20-generic; amd64)'
        request.env['HTTP_USER_AGENT'] = agent

        expect(Gitlab::UsageDataCounters::JetBrainsBundledPluginActivityUniqueCounter)
          .to receive(:track_api_request_when_trackable).with(user_agent: agent, user: user)

        post :execute
      end

      it 'calls the track visual studio extension api when trackable method' do
        agent = 'code-completions-language-server-experiment (gl-visual-studio-extension:1.0.0.0; arch:X64;)'
        request.env['HTTP_USER_AGENT'] = agent

        expect(Gitlab::UsageDataCounters::VisualStudioExtensionActivityUniqueCounter)
          .to receive(:track_api_request_when_trackable).with(user_agent: agent, user: user)

        post :execute
      end

      it 'calls the track neovim plugin api when trackable method' do
        agent = 'code-completions-language-server-experiment (Neovim:0.9.0; gitlab.vim (v0.1.0); arch:amd64; os:darwin)'
        request.env['HTTP_USER_AGENT'] = agent

        expect(Gitlab::UsageDataCounters::NeovimPluginActivityUniqueCounter)
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

      shared_examples 'invalid token' do
        it 'returns 401 with invalid token message' do
          subject

          expect(response).to have_gitlab_http_status(:unauthorized)
          expect_graphql_errors_to_include('Invalid token')
        end
      end

      context 'with an expired token' do
        let(:token) { create(:personal_access_token, :expired, user: user, scopes: [:api]) }

        it_behaves_like 'invalid token'

        it 'registers token_expire in application context' do
          subject

          expect(app_context['meta.auth_fail_reason']).to eq('token_expired')
          expect(app_context['meta.auth_fail_token_id']).to eq("PersonalAccessToken/#{token.id}")
          expect(app_context['meta.auth_fail_requested_scopes']).to include('api read_api')
        end
      end

      context 'with a revoked token' do
        let(:token) { create(:personal_access_token, :revoked, user: user, scopes: [:api]) }

        it_behaves_like 'invalid token'

        it 'registers token_expire in application context' do
          subject

          expect(app_context['meta.auth_fail_reason']).to eq('token_revoked')
          expect(app_context['meta.auth_fail_token_id']).to eq("PersonalAccessToken/#{token.id}")
          expect(app_context['meta.auth_fail_requested_scopes']).to include('api read_api')
        end
      end

      context 'with an invalid token' do
        context 'with auth header' do
          subject do
            request.headers[header] = 'invalid'
            post :execute, params: { query: query, user: nil }
          end

          context 'with private-token' do
            let(:header) { 'Private-Token' }

            it_behaves_like 'invalid token'
          end

          context 'with job-token' do
            let(:header) { 'Job-Token' }

            it_behaves_like 'invalid token'
          end

          context 'with deploy-token' do
            let(:header) { 'Deploy-Token' }

            it_behaves_like 'invalid token'
          end
        end

        context 'with authorization bearer (oauth token)' do
          subject do
            request.headers['Authorization'] = 'Bearer invalid'
            post :execute, params: { query: query, user: nil }
          end

          it_behaves_like 'invalid token'
        end

        context 'with auth param' do
          subject { post :execute, params: { query: query, user: nil }.merge(header) }

          context 'with private_token' do
            let(:header) { { private_token: 'invalid' } }

            it_behaves_like 'invalid token'
          end

          context 'with job_token' do
            let(:header) { { job_token: 'invalid' } }

            it_behaves_like 'invalid token'
          end

          context 'with token' do
            let(:header) { { token: 'invalid' } }

            it_behaves_like 'invalid token'
          end
        end
      end

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

        expect(app_context).to include('meta.user' => user.username)
        expect(app_context.keys).not_to include('meta.auth_fail_reason',
          'meta.auth_fail_token_id',
          'meta.auth_fail_requested_scopes')
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

      it 'calls the track jetbrains bundled third party api when trackable method' do
        agent = 'IntelliJ-GitLab-Plugin PhpStorm/PS-232.6734.11 (JRE 17.0.7+7-b966.2; Linux 6.2.0-20-generic; amd64)'
        request.env['HTTP_USER_AGENT'] = agent

        expect(Gitlab::UsageDataCounters::JetBrainsBundledPluginActivityUniqueCounter)
          .to receive(:track_api_request_when_trackable).with(user_agent: agent, user: user)

        subject
      end

      it 'calls the track visual studio extension api when trackable method' do
        agent = 'code-completions-language-server-experiment (gl-visual-studio-extension:1.0.0.0; arch:X64;)'
        request.env['HTTP_USER_AGENT'] = agent

        expect(Gitlab::UsageDataCounters::VisualStudioExtensionActivityUniqueCounter)
          .to receive(:track_api_request_when_trackable).with(user_agent: agent, user: user)

        subject
      end

      it 'calls the track neovim plugin api when trackable method' do
        agent = 'code-completions-language-server-experiment (Neovim:0.9.0; gitlab.vim (v0.1.0); arch:amd64; os:darwin)'
        request.env['HTTP_USER_AGENT'] = agent

        expect(Gitlab::UsageDataCounters::NeovimPluginActivityUniqueCounter)
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

    describe 'DPoP authentication' do
      context 'when :dpop_authentication FF is disabled' do
        let(:user) { create(:user, last_activity_on: last_activity_on) }
        let(:personal_access_token) { create(:personal_access_token, user: user, scopes: [:api]) }

        it 'does not check for DPoP token' do
          stub_feature_flags(dpop_authentication: false)

          post :execute, params: { access_token: personal_access_token.token }
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when :dpop_authentication FF is enabled' do
        before do
          stub_feature_flags(dpop_authentication: true)
        end

        context 'when DPoP is disabled for the user' do
          let(:user) { create(:user, last_activity_on: last_activity_on) }
          let(:personal_access_token) { create(:personal_access_token, user: user, scopes: [:api]) }

          it 'does not check for DPoP token' do
            post :execute, params: { access_token: personal_access_token.token }
            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'when DPoP is enabled for the user' do
          let_it_be(:user) { create(:user, last_activity_on: last_activity_on, dpop_enabled: true) }
          let_it_be(:personal_access_token) { create(:personal_access_token, user: user, scopes: [:api]) }
          let_it_be(:oauth_token) { create(:oauth_access_token, user: user, scopes: [:api]) }
          let_it_be(:dpop_proof) { generate_dpop_proof_for(user) }

          context 'when API is called with an OAuth token' do
            it 'does not invoke DPoP' do
              request.headers["Authorization"] = "Bearer #{oauth_token.plaintext_token}"
              post :execute
              expect(response).to have_gitlab_http_status(:ok)
            end
          end

          context 'with a missing DPoP token' do
            it 'returns 401' do
              post :execute, params: { access_token: personal_access_token.token }
              expect(response).to have_gitlab_http_status(:unauthorized)
              expect(json_response["errors"][0]["message"]).to eq("DPoP validation error: DPoP header is missing")
            end
          end

          context 'with a valid DPoP token' do
            it 'returns 200' do
              request.headers["dpop"] = dpop_proof.proof
              post :execute, params: { access_token: personal_access_token.token }
              expect(response).to have_gitlab_http_status(:ok)
            end
          end

          context 'with a malformed DPoP token' do
            it 'returns 401' do
              request.headers["dpop"] = "invalid"
              post :execute, params: { access_token: personal_access_token.token } # -- We need the entire error message
              expect(json_response["errors"][0]["message"])
                .to eq("DPoP validation error: Malformed JWT, unable to decode. Not enough or too many segments")
              expect(response).to have_gitlab_http_status(:unauthorized)
            end
          end
        end
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

        expect(app_context.key?('meta.user')).to be false
        expect(app_context.keys).not_to include('meta.auth_fail_reason',
          'meta.auth_fail_token_id',
          'meta.auth_fail_requested_scopes')
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

    context 'when querying an IntrospectionQuery', :use_clean_rails_memory_store_caching do
      let_it_be(:query) { CachedIntrospectionQuery.query_string }

      context 'in dev or test env' do
        before do
          allow(Gitlab).to receive(:dev_or_test_env?).and_return(true)
        end

        it 'does not cache IntrospectionQuery' do
          expect(GitlabSchema).to receive(:execute).exactly(:twice)

          post :execute, params: { query: query }
          post :execute, params: { query: query }
        end
      end

      context 'in env different from dev or test' do
        before do
          allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
        end

        it 'caches IntrospectionQuery even when operationName is not given' do
          expect(GitlabSchema).to receive(:execute).exactly(:once)

          post :execute, params: { query: query }
          post :execute, params: { query: query }
        end

        it 'caches the IntrospectionQuery' do
          expect(GitlabSchema).to receive(:execute).exactly(:once)

          post :execute, params: { query: query, operationName: 'IntrospectionQuery' }
          post :execute, params: { query: query, operationName: 'IntrospectionQuery' }
        end

        it 'caches separately for both remove_deprecated set to true and false' do
          expect(GitlabSchema).to receive(:execute).exactly(:twice)

          post :execute, params: { query: query, operationName: 'IntrospectionQuery', remove_deprecated: true }
          post :execute, params: { query: query, operationName: 'IntrospectionQuery', remove_deprecated: true }

          # We clear this instance variable to reset remove_deprecated
          subject.remove_instance_variable(:@context) if subject.instance_variable_defined?(:@context)

          post :execute, params: { query: query, operationName: 'IntrospectionQuery', remove_deprecated: false }
          post :execute, params: { query: query, operationName: 'IntrospectionQuery', remove_deprecated: false }
        end

        it 'has a different cache for each Gitlab.revision' do
          expect(GitlabSchema).to receive(:execute).exactly(:twice)

          post :execute, params: { query: query, operationName: 'IntrospectionQuery' }

          allow(Gitlab).to receive(:revision).and_return('new random value')

          post :execute, params: { query: query, operationName: 'IntrospectionQuery' }
        end

        context 'when there is an unknown introspection query' do
          let(:query) { File.read(Rails.root.join('spec/fixtures/api/graphql/fake_introspection.graphql')) }

          it 'does not cache an unknown introspection query' do
            expect(GitlabSchema).to receive(:execute).exactly(:twice)

            post :execute, params: { query: query, operationName: 'IntrospectionQuery' }
            post :execute, params: { query: query, operationName: 'IntrospectionQuery' }
          end
        end

        it 'hits the cache even if the whitespace in the query differs' do
          query_1 = CachedIntrospectionQuery.query_string
          query_2 = "#{query_1}  " # add a couple of spaces to change the fingerprint

          expect(GitlabSchema).to receive(:execute).exactly(:once)

          post :execute, params: { query: query_1, operationName: 'IntrospectionQuery' }
          post :execute, params: { query: query_2, operationName: 'IntrospectionQuery' }
        end
      end

      context 'when performing a multiplex query as an IntrospectionQuery' do
        let(:user) { create(:user) }
        let_it_be(:query) do
          <<~GQL
            mutation IntrospectionQuery{createSnippet(input:{title:"test" description:"test" visibilityLevel:public blobActions:[{action:create previousPath:"test" filePath:"test" content:"test new file"}]}){errors clientMutationId snippet{webUrl}}}
          GQL
        end

        before do
          sign_in(user)
        end

        it 'does not perform a mutation' do
          expect do
            get :execute,
              params: { query: query, operationName: 'IntrospectionQuery', _json: ["[query]=query {__typename}"] }
          end.not_to change {
            Snippet.count
          }
        end

        it 'does not call GitlabSchema.execute' do
          expect(GitlabSchema).not_to receive(:execute)
          expect(GitlabSchema).to receive(:multiplex)

          get :execute,
            params: { query: query, operationName: 'IntrospectionQuery', _json: ["[query]=query {__typename}"] }
        end
      end
    end

    context 'when X_GITLAB_DISABLE_SQL_QUERY_LIMIT is set' do
      let(:issue_url) { "http://some/issue/url" }
      let(:limit) { 205 }

      context 'and it specifies a new query limit' do
        let(:header_value) { "#{limit},#{issue_url}" }

        it 'respects the new query limit' do
          expect(Gitlab::QueryLimiting).to receive(:disable!).with(issue_url, new_threshold: limit)

          request.env['HTTP_X_GITLAB_DISABLE_SQL_QUERY_LIMIT'] = header_value

          post :execute
        end
      end

      context 'and it does not specify a new limit' do
        let(:header_value) { issue_url }

        it 'disables limit' do
          expect(Gitlab::QueryLimiting).to receive(:disable!).with(issue_url)

          request.env['HTTP_X_GITLAB_DISABLE_SQL_QUERY_LIMIT'] = header_value

          post :execute
        end
      end
    end
  end

  describe 'Admin Mode' do
    let_it_be(:admin) { create(:admin) }
    let_it_be(:project) { create(:project) }

    let(:graphql_query) { graphql_query_for('project', { 'fullPath' => project.full_path }, %w[id name]) }

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
    let(:query_1) { { query: graphql_query_for('project', { 'fullPath' => 'foo' }, %w[id name], 'getProject_1') } }
    let(:query_2) { { query: graphql_query_for('project', { 'fullPath' => 'bar' }, %w[id], 'getProject_2') } }
    let(:graphql_queries) { [query_1, query_2] }
    let(:log_payload) { {} }
    let(:expected_logs) do
      [
        {
          operation_name: 'getProject_1',
          complexity: 3,
          depth: 2,
          used_deprecated_arguments: [],
          used_deprecated_fields: [],
          used_fields: ['Project.id', 'Project.name', 'Query.project'],
          variables: '{}'
        },
        {
          operation_name: 'getProject_2',
          complexity: 2,
          depth: 2,
          used_deprecated_arguments: [],
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

    context 'when source is not glql' do
      it 'appends metadata for logging' do
        post :execute, params: { _json: graphql_queries }

        expect(controller).to have_received(:append_info_to_payload)
        expect(log_payload.dig(:metadata, :graphql)).to match_array(expected_logs)
        expect(log_payload.dig(:metadata, :referer)).to be_nil
      end
    end

    context 'when source is glql' do
      let(:query_1) { { query: graphql_query_for('project', { 'fullPath' => 'foo' }, %w[id name], 'GLQL') } }
      let(:query_2) { { query: graphql_query_for('project', { 'fullPath' => 'bar' }, %w[id], 'GLQL') } }

      let(:expected_glql_logs) do
        expected_logs.map do |q|
          q.merge(operation_name: "GLQL")
        end
      end

      before do
        request.headers['Referer'] = 'path'
      end

      it 'appends glql-related metadata for logging' do
        post :execute, params: { _json: graphql_queries }

        expect(controller).to have_received(:append_info_to_payload)
        expect(log_payload.dig(:metadata, :graphql)).to match_array(expected_glql_logs)
        expect(log_payload.dig(:metadata, :referer)).to eq('path')
      end
    end

    it 'appends the exception in case of errors' do
      exception = StandardError.new('boom')

      expect(controller).to receive(:execute).and_raise(exception)

      post :execute, params: { _json: graphql_queries }

      expect(controller).to have_received(:append_info_to_payload)
      expect(log_payload[:exception_object]).to eq(exception)
    end
  end
end
