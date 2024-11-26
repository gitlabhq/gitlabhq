# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PipelinesController, feature_category: :continuous_integration do
  include ApiHelpers

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :public, :repository) }

  let(:feature) { ProjectFeature::ENABLED }

  before do
    allow(Sidekiq.logger).to receive(:info)
    stub_not_protect_default_branch
    project.add_developer(user)
    project.project_feature.update!(builds_access_level: feature)

    sign_in(user)
  end

  shared_examples 'the show page' do |param|
    it 'renders the show template' do
      get param, params: { namespace_id: project.namespace, project_id: project, id: pipeline }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template :show
    end
  end

  describe 'GET index.json' do
    before do
      create_all_pipeline_types
    end

    context 'when using persisted stages', :request_store do
      render_views

      it 'returns serialized pipelines' do
        expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original

        get_pipelines_index_json

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('pipeline')

        expect(json_response).to include('pipelines')
        expect(json_response['pipelines'].count).to eq 6
        expect(json_response['count']['all']).to eq '6'

        json_response.dig('pipelines', 0, 'details', 'stages').tap do |stages|
          expect(stages.count).to eq 3
        end
      end
    end

    it 'does not include coverage data for the pipelines' do
      get_pipelines_index_json

      expect(json_response['pipelines'][0]).not_to include('coverage')
    end

    it 'paginates the result' do
      allow(Ci::Pipeline).to receive(:default_per_page).and_return(2)

      get_pipelines_index_json

      check_pipeline_response(returned: 2, all: 6)
    end

    context 'when performing gitaly calls', :request_store, :use_null_store_as_repository_cache do
      it 'limits the Gitaly requests' do
        # Isolate from test preparation (Repository#exists? is also cached in RequestStore)
        RequestStore.end!
        RequestStore.clear!
        RequestStore.begin!

        expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original

        # ListCommitsByOid, RepositoryExists, HasLocalBranches, ListCommitsByRefNames
        expect { get_pipelines_index_json }
          .to change { Gitlab::GitalyClient.get_request_count }.by(4)
      end
    end

    context 'when the project is private' do
      let(:project) { create(:project, :private, :repository) }

      it 'returns `not_found` when the user does not have access' do
        sign_in(create(:user))

        get_pipelines_index_json

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns the pipelines when the user has access' do
        get_pipelines_index_json

        expect(json_response['pipelines'].size).to eq(6)
      end
    end

    context 'when user tries to access legacy scope via URL' do
      it 'redirects to all pipelines with that status instead' do
        get_pipelines_index_html(scope: 'running')

        expect(response).to redirect_to(project_pipelines_path(project, status: 'running', format: :html))
      end
    end

    context 'filter by scope' do
      context 'scope is branches or tags' do
        before do
          create(:ci_pipeline, :failed, project: project, ref: 'v1.0.0', tag: true)
          create(:ci_pipeline, :failed, project: project, ref: 'master', tag: false)
          create(:ci_pipeline, :failed, project: project, ref: 'feature', tag: false)
        end

        context 'when scope is branches' do
          it 'returns matched pipelines' do
            get_pipelines_index_json(scope: 'branches')

            check_pipeline_response(returned: 2, all: 9)
          end
        end

        context 'when scope is tags' do
          it 'returns matched pipelines' do
            get_pipelines_index_json(scope: 'tags')

            check_pipeline_response(returned: 1, all: 9)
          end
        end
      end
    end

    context 'filter by username' do
      let!(:pipeline) { create(:ci_pipeline, :running, project: project, user: user) }

      context 'when username exists' do
        it 'returns matched pipelines' do
          get_pipelines_index_json(username: user.username)

          check_pipeline_response(returned: 1, all: 1)
        end
      end

      context 'when username does not exist' do
        it 'returns empty' do
          get_pipelines_index_json(username: 'invalid-username')

          check_pipeline_response(returned: 0, all: 0)
        end
      end
    end

    context 'filter by ref' do
      let!(:pipeline) { create(:ci_pipeline, :running, project: project, ref: 'branch-1') }

      context 'when pipelines with the ref exists' do
        it 'returns matched pipelines' do
          get_pipelines_index_json(ref: 'branch-1')

          check_pipeline_response(returned: 1, all: 1)
        end
      end

      context 'when no pipeline with the ref exists' do
        it 'returns empty list' do
          get_pipelines_index_json(ref: 'invalid-ref')

          check_pipeline_response(returned: 0, all: 0)
        end
      end
    end

    context 'filter by status' do
      context 'when pipelines with the status exists' do
        it 'returns matched pipelines' do
          get_pipelines_index_json(status: 'success')

          check_pipeline_response(returned: 1, all: 1)
        end
      end

      context 'when no pipeline with the status exists' do
        it 'returns empty list' do
          get_pipelines_index_json(status: 'manual')

          check_pipeline_response(returned: 0, all: 0)
        end
      end

      context 'when invalid status' do
        it 'returns all list' do
          get_pipelines_index_json(status: 'invalid-status')

          check_pipeline_response(returned: 6, all: 6)
        end
      end
    end

    def get_pipelines_index_html(params = {})
      get :index, params: {
        namespace_id: project.namespace,
        project_id: project
      }.merge(params), format: :html
    end

    def get_pipelines_index_json(params = {})
      get :index, params: {
        namespace_id: project.namespace,
        project_id: project
      }.merge(params), format: :json
    end

    def create_all_pipeline_types
      %w[pending running success failed canceled].each_with_index do |status, index|
        create_pipeline(status, project.commit("HEAD~#{index}"))
      end

      create_pipeline_with_merge_request
    end

    def create_pipeline_with_merge_request
      # New merge requests must be created with different branches, so
      # let's just create new ones with random names.
      branch_name = "test-#{SecureRandom.hex}"
      project.repository.create_branch(branch_name, project.repository.root_ref)
      mr = create(:merge_request, source_project: project, target_project: project, source_branch: branch_name)
      create_pipeline(:running, project.commit('HEAD'), merge_request: mr)
    end

    def create_pipeline(status, sha, merge_request: nil)
      user = create(:user)
      pipeline = create(
        :ci_empty_pipeline,
        status: status,
        project: project,
        sha: sha.id,
        ref: sha.id.first(8),
        user: user,
        merge_request: merge_request
      )

      build_stage = create(:ci_stage, name: 'build', pipeline: pipeline)
      test_stage = create(:ci_stage, name: 'test', pipeline: pipeline)
      deploy_stage = create(:ci_stage, name: 'deploy', pipeline: pipeline)

      create_build(pipeline, build_stage, 1, 'build', user)
      create_build(pipeline, test_stage, 2, 'test', user)
      create_build(pipeline, deploy_stage, 3, 'deploy', user)

      pipeline
    end

    def create_build(pipeline, stage, stage_idx, name, user = nil)
      status = %w[created running pending success failed canceled].sample
      create(
        :ci_build,
        :artifacts,
        artifacts_expire_at: 2.days.from_now,
        pipeline: pipeline,
        ci_stage: stage,
        stage_idx: stage_idx,
        name: name,
        status: status,
        user: user
      )
    end

    def check_pipeline_response(returned:, all:)
      aggregate_failures do
        expect(response).to match_response_schema('pipeline')

        expect(json_response['pipelines'].count).to eq returned
        expect(json_response['count']['all'].to_i).to eq all
      end
    end
  end

  describe 'GET #show' do
    def get_pipeline_html
      get :show, params: { namespace_id: project.namespace, project_id: project, id: pipeline }, format: :html
    end

    context 'when the project is public' do
      render_views

      let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
      let_it_be(:build_stage) { create(:ci_stage, name: 'build', pipeline: pipeline) }
      let_it_be(:test_stage) { create(:ci_stage, name: 'test', pipeline: pipeline) }
      let_it_be(:deploy_stage) { create(:ci_stage, name: 'deploy', pipeline: pipeline) }

      def create_build_with_artifacts(stage, stage_idx, name, status)
        create(:ci_build, :artifacts, :tags, status, user: user, pipeline: pipeline, ci_stage: stage, stage_idx: stage_idx, name: name)
      end

      def create_bridge(stage, stage_idx, name, status)
        create(:ci_bridge, status, pipeline: pipeline, ci_stage: stage, stage_idx: stage_idx, name: name)
      end

      before do
        create_build_with_artifacts(build_stage, 0, 'job1', :failed)
        create_build_with_artifacts(build_stage, 0, 'job2', :running)
        create_build_with_artifacts(build_stage, 0, 'job3', :pending)
        create_bridge(deploy_stage, 1, 'deploy-a', :failed)
        create_bridge(deploy_stage, 1, 'deploy-b', :created)
      end

      it 'avoids N+1 database queries', :request_store, :use_sql_query_cache do
        # warm up
        get_pipeline_html
        expect(response).to have_gitlab_http_status(:ok)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          get_pipeline_html
          expect(response).to have_gitlab_http_status(:ok)
        end

        create_build_with_artifacts(build_stage, 0, 'job4', :failed)
        create_build_with_artifacts(build_stage, 0, 'job5', :running)
        create_build_with_artifacts(build_stage, 0, 'job6', :pending)
        create_bridge(deploy_stage, 1, 'deploy-c', :failed)
        create_bridge(deploy_stage, 1, 'deploy-d', :created)

        expect do
          get_pipeline_html
          expect(response).to have_gitlab_http_status(:ok)
        end.not_to exceed_all_query_limit(control).with_threshold(3)
      end
    end

    context 'when the project is private' do
      let(:project) { create(:project, :private, :repository) }
      let(:pipeline) { create(:ci_pipeline, project: project) }

      it 'returns `not_found` when the user does not have access' do
        sign_in(create(:user))

        get_pipeline_html

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET show.json' do
    let(:pipeline) { create(:ci_pipeline, project: project) }

    it 'returns the pipeline' do
      get_pipeline_json

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).not_to be_an(Array)
      expect(json_response['id']).to be(pipeline.id)
      expect(json_response['details']).to have_key 'stages'
    end

    context 'when the pipeline has multiple stages and groups', :request_store do
      let(:project) { create(:project, :repository) }

      let(:pipeline) do
        create(:ci_empty_pipeline, project: project, user: user, sha: project.commit.id)
      end

      let(:build_stage) { create(:ci_stage, name: 'build', pipeline: pipeline) }
      let(:test_stage) { create(:ci_stage, name: 'test', pipeline: pipeline) }
      let(:deploy_stage) { create(:ci_stage, name: 'deploy', pipeline: pipeline) }
      let(:post_deploy_stage) { create(:ci_stage, name: 'post deploy', pipeline: pipeline) }

      before do
        create_build(build_stage, 0, 'build')
        create_build(test_stage, 1, 'rspec 0')
        create_build(deploy_stage, 2, 'production')
        create_build(post_deploy_stage, 3, 'pages 0')
      end

      it 'does not perform N + 1 queries' do
        # Set up all required variables
        get_pipeline_json

        control = ActiveRecord::QueryRecorder.new { get_pipeline_json }

        first_build = pipeline.builds.first
        first_build.tag_list << [:hello, :world]
        create(:deployment, deployable: first_build)

        second_build = pipeline.builds.second
        second_build.tag_list << [:docker, :ruby]
        create(:deployment, deployable: second_build)

        expect { get_pipeline_json }.not_to exceed_query_limit(control).with_threshold(1)
      end
    end

    context 'when builds are disabled' do
      let(:feature) { ProjectFeature::DISABLED }

      it 'users can not see internal pipelines' do
        get_pipeline_json

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when pipeline is external' do
        let(:pipeline) { create(:ci_pipeline, source: :external, project: project) }

        it 'users can see the external pipeline' do
          get_pipeline_json

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to be(pipeline.id)
        end
      end
    end

    context 'with triggered pipelines' do
      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:source_project) { create(:project, :repository) }
      let_it_be(:target_project) { create(:project, :repository) }
      let_it_be(:root_pipeline) { create_pipeline(project) }
      let_it_be(:source_pipeline) { create_pipeline(source_project) }
      let_it_be(:source_of_source_pipeline) { create_pipeline(source_project) }
      let_it_be(:target_pipeline) { create_pipeline(target_project) }
      let_it_be(:target_of_target_pipeline) { create_pipeline(target_project) }

      before do
        create_link(source_of_source_pipeline, source_pipeline)
        create_link(source_pipeline, root_pipeline)
        create_link(root_pipeline, target_pipeline)
        create_link(target_pipeline, target_of_target_pipeline)
      end

      shared_examples 'not expanded' do
        let(:expected_stages) { be_nil }

        it 'does return base details' do
          get_pipeline_json(root_pipeline)

          expect(json_response['triggered_by']).to include('id' => source_pipeline.id)
          expect(json_response['triggered']).to contain_exactly(
            include('id' => target_pipeline.id))
        end

        it 'does not expand triggered_by pipeline' do
          get_pipeline_json(root_pipeline)

          triggered_by = json_response['triggered_by']
          expect(triggered_by['triggered_by']).to be_nil
          expect(triggered_by['triggered']).to be_nil
          expect(triggered_by['details']['stages']).to expected_stages
        end

        it 'does not expand triggered pipelines' do
          get_pipeline_json(root_pipeline)

          first_triggered = json_response['triggered'].first
          expect(first_triggered['triggered_by']).to be_nil
          expect(first_triggered['triggered']).to be_nil
          expect(first_triggered['details']['stages']).to expected_stages
        end
      end

      shared_examples 'expanded' do
        it 'does return base details' do
          get_pipeline_json(root_pipeline)

          expect(json_response['triggered_by']).to include('id' => source_pipeline.id)
          expect(json_response['triggered']).to contain_exactly(
            include('id' => target_pipeline.id))
        end

        it 'does expand triggered_by pipeline' do
          get_pipeline_json(root_pipeline)

          triggered_by = json_response['triggered_by']
          expect(triggered_by['triggered_by']).to include(
            'id' => source_of_source_pipeline.id)
          expect(triggered_by['details']['stages']).not_to be_nil
        end

        it 'does not recursively expand triggered_by' do
          get_pipeline_json(root_pipeline)

          triggered_by = json_response['triggered_by']
          expect(triggered_by['triggered']).to be_nil
        end

        it 'does expand triggered pipelines' do
          get_pipeline_json(root_pipeline)

          first_triggered = json_response['triggered'].first
          expect(first_triggered['triggered']).to contain_exactly(
            include('id' => target_of_target_pipeline.id))
          expect(first_triggered['details']['stages']).not_to be_nil
        end

        it 'does not recursively expand triggered' do
          get_pipeline_json(root_pipeline)

          first_triggered = json_response['triggered'].first
          expect(first_triggered['triggered_by']).to be_nil
        end
      end

      context 'when it does have permission to read other projects' do
        before do
          source_project.add_developer(user)
          target_project.add_developer(user)
        end

        context 'when not-expanding any pipelines' do
          let(:expanded) { nil }

          it_behaves_like 'not expanded'
        end

        context 'when expanding non-existing pipeline' do
          let(:expanded) { [-1] }

          it_behaves_like 'not expanded'
        end

        context 'when expanding pipeline that is not directly expandable' do
          let(:expanded) { [source_of_source_pipeline.id, target_of_target_pipeline.id] }

          it_behaves_like 'not expanded'
        end

        context 'when expanding self' do
          let(:expanded) { [root_pipeline.id] }

          context 'it does not recursively expand pipelines' do
            it_behaves_like 'not expanded'
          end
        end

        context 'when expanding source and target pipeline' do
          let(:expanded) { [source_pipeline.id, target_pipeline.id] }

          it_behaves_like 'expanded'

          context 'when expand depth is limited to 1' do
            before do
              stub_const('TriggeredPipelineEntity::MAX_EXPAND_DEPTH', 1)
            end

            it_behaves_like 'not expanded' do
              # We expect that triggered/triggered_by is not expanded,
              # but we still return details.stages for that pipeline
              let(:expected_stages) { be_a(Array) }
            end
          end
        end

        context 'when expanding all' do
          let(:expanded) do
            [
              source_of_source_pipeline.id,
              source_pipeline.id,
              root_pipeline.id,
              target_pipeline.id,
              target_of_target_pipeline.id
            ]
          end

          it_behaves_like 'expanded'
        end
      end

      context 'when does not have permission to read other projects' do
        let(:expanded) { [source_pipeline.id, target_pipeline.id] }

        it_behaves_like 'not expanded'
      end

      def create_pipeline(project)
        create(:ci_empty_pipeline, project: project).tap do |pipeline|
          create(:ci_build, pipeline: pipeline, ci_stage: create(:ci_stage, name: 'test', pipeline: pipeline), name: 'rspec')
        end
      end

      def create_link(source_pipeline, pipeline)
        source_pipeline.sourced_pipelines.create!(
          source_job: source_pipeline.builds.all.sample,
          source_project: source_pipeline.project,
          project: pipeline.project,
          pipeline: pipeline
        )
      end

      def get_pipeline_json(pipeline)
        params = {
          namespace_id: pipeline.project.namespace,
          project_id: pipeline.project,
          id: pipeline,
          expanded: expanded
        }

        get :show, params: params.compact, format: :json
      end
    end

    def get_pipeline_json
      get :show, params: { namespace_id: project.namespace, project_id: project, id: pipeline }, format: :json
    end

    def create_build(stage, stage_idx, name)
      create(:ci_build, pipeline: pipeline, ci_stage: stage, stage_idx: stage_idx, name: name)
    end
  end

  describe 'GET builds' do
    let(:pipeline) { create(:ci_pipeline, project: project) }

    it_behaves_like 'the show page', 'builds'
  end

  describe 'GET failures' do
    let(:pipeline) { create(:ci_pipeline, project: project) }

    context 'with failed jobs' do
      before do
        create(:ci_build, :failed, pipeline: pipeline, name: 'hello')
      end

      it 'shows the page' do
        get :failures, params: { namespace_id: project.namespace, project_id: project, id: pipeline }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template :show
      end
    end

    context 'without failed jobs' do
      it 'redirects to the main pipeline page' do
        get :failures, params: { namespace_id: project.namespace, project_id: project, id: pipeline }

        expect(response).to redirect_to(pipeline_path(pipeline))
      end
    end
  end

  describe 'GET stages.json' do
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:build_stage) { create(:ci_stage, name: 'build', pipeline: pipeline) }

    context 'when accessing existing stage' do
      before do
        create(:ci_build, :retried, :failed, pipeline: pipeline, ci_stage: build_stage)
        create(:ci_build, pipeline: pipeline, ci_stage: build_stage)
      end

      context 'without retried' do
        before do
          get_stage('build')
        end

        it 'returns pipeline jobs without the retried builds' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('pipeline_stage')
          expect(json_response['latest_statuses'].length).to eq 1
          expect(json_response).not_to have_key('retried')
        end
      end

      context 'with retried' do
        before do
          get_stage('build', retried: true)
        end

        it 'returns pipelines jobs with the retried builds' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('pipeline_stage')
          expect(json_response['latest_statuses'].length).to eq 1
          expect(json_response['retried'].length).to eq 1
        end
      end
    end

    context 'when accessing unknown stage' do
      before do
        get_stage('test')
      end

      it 'responds with not found' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def get_stage(name, params = {})
      get :stage, params: {
**params.merge(
  namespace_id: project.namespace,
  project_id: project,
  id: pipeline.id,
  stage: name,
  format: :json)
}
    end
  end

  describe 'GET status.json' do
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:status) { pipeline.detailed_status(double('user')) }

    before do
      get :status, params: {
        namespace_id: project.namespace, project_id: project, id: pipeline.id
      }, format: :json
    end

    it 'return a detailed pipeline status in json' do
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['text']).to eq status.text
      expect(json_response['label']).to eq status.label
      expect(json_response['icon']).to eq status.icon
      expect(json_response['favicon']).to match_asset_path("/assets/ci_favicons/#{status.favicon}.png")
    end
  end

  describe 'GET #charts' do
    let(:pipeline) { create(:ci_pipeline, project: project) }

    [
      {
        chart_param: 'time-to-restore-service',
        event: 'visit_ci_cd_time_to_restore_service_tab'
      },
      {
        chart_param: 'change-failure-rate',
        event: 'visit_ci_cd_failure_rate_tab'
      }
    ].each do |tab|
      it 'tracks internal events' do
        request_params = { namespace_id: project.namespace, project_id: project, id: pipeline.id, chart: tab[:chart_param] }

        expect { get :charts, params: request_params, format: :html }.to trigger_internal_events(tab[:event])
      end
    end

    using RSpec::Parameterized::TableSyntax

    where(:chart, :event, :additional_metrics) do
      ''                        | 'p_analytics_ci_cd_pipelines'               | ['analytics_unique_visits.p_analytics_ci_cd_pipelines']
      'pipelines'               | 'p_analytics_ci_cd_pipelines'               | ['analytics_unique_visits.p_analytics_ci_cd_pipelines']
      'deployment-frequency'    | 'p_analytics_ci_cd_deployment_frequency'    | []
      'lead-time'               | 'p_analytics_ci_cd_lead_time'               | []
    end

    with_them do
      let!(:params) { { namespace_id: project.namespace, project_id: project, id: pipeline.id, chart: chart } }

      it_behaves_like 'tracking unique visits', :charts do
        let(:request_params) { params }
        let(:target_id) { ['p_analytics_pipelines', event] }
      end

      it 'tracks events and increment usage metrics', :clean_gitlab_redis_shared_state do
        expect { get :charts, params: params, format: :html }
          .to trigger_internal_events(event).with(project: project, user: user, category: 'InternalEventTracking')
          .and increment_usage_metrics(
            # These are currently double-counted --- what's up with this?; is it the mix of track_internal_events and track_events?
            # Or that track_internal_events is being used with events which aren't actually internal_events?
            'analytics_unique_visits.analytics_unique_visits_for_any_target',
            'analytics_unique_visits.analytics_unique_visits_for_any_target_monthly',
            'redis_hll_counters.analytics.analytics_total_unique_counts_monthly',
            'redis_hll_counters.analytics.analytics_total_unique_counts_weekly'
          ).by(2)
          .and increment_usage_metrics(
            "redis_hll_counters.analytics.#{event}_monthly",
            "redis_hll_counters.analytics.#{event}_weekly",
            *additional_metrics
          ).by(1)
      end
    end
  end

  describe 'POST create' do
    let(:project) { create(:project, :public, :repository) }

    before do
      project.add_developer(user)
      project.project_feature.update!(builds_access_level: feature)
    end

    context 'with a valid .gitlab-ci.yml file' do
      before do
        stub_ci_pipeline_yaml_file(YAML.dump({
          test: {
            stage: 'test',
            script: 'echo'
          }
        }))
      end

      shared_examples 'creates a pipeline' do
        specify do
          expect { post_request }.to change { project.ci_pipelines.count }.by(1)

          pipeline = project.ci_pipelines.last
          expected_redirect_path = Gitlab::Routing.url_helpers.project_pipeline_path(project, pipeline)
          expect(pipeline).to be_created
          expect(response).to redirect_to(expected_redirect_path)
        end
      end

      it_behaves_like 'creates a pipeline'

      context 'when latest commit contains [ci skip]' do
        before do
          project.repository.create_file(user, 'new-file.txt', 'A new file', message: '[skip ci] This is a test', branch_name: 'master')
        end

        it_behaves_like 'creates a pipeline'
      end
    end

    context 'with an invalid .gitlab-ci.yml file' do
      before do
        stub_ci_pipeline_yaml_file('invalid yaml file')
      end

      it 'does not persist a pipeline' do
        expect { post_request }.not_to change { project.ci_pipelines.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(response).to render_template('new')
      end
    end

    def post_request
      post :create, params: {
        namespace_id: project.namespace,
        project_id: project,
        pipeline: {
          ref: 'master'
        }
      }
    end
  end

  describe 'POST create.json' do
    let(:project) { create(:project, :public, :repository) }

    subject do
      post :create, params: {
        namespace_id: project.namespace, project_id: project, pipeline: { ref: 'master' }
      }, format: :json
    end

    before do
      project.add_developer(user)
      project.project_feature.update!(builds_access_level: feature)
    end

    context 'with a valid .gitlab-ci.yml file' do
      before do
        stub_ci_pipeline_yaml_file(YAML.dump({
          test: {
            stage: 'test',
            script: 'echo'
          }
        }))
      end

      it 'creates a pipeline' do
        expect { subject }.to change { project.ci_pipelines.count }.by(1)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['id']).to eq(project.ci_pipelines.last.id)
      end
    end

    context 'with an invalid .gitlab-ci.yml file' do
      before do
        stub_ci_pipeline_yaml_file(YAML.dump({
          build: {
            stage: 'build',
            script: 'echo',
            rules: [{ when: 'always' }]
          },
          test: {
            stage: 'invalid',
            script: 'echo'
          }
        }))
      end

      it 'does not create a pipeline' do
        expect { subject }.not_to change { project.ci_pipelines.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['errors']).to eq([
          'test job: chosen stage invalid does not exist; available stages are .pre, build, test, deploy, .post'
        ])
        expect(json_response['warnings'][0]).to include(
          'jobs:build may allow multiple pipelines to run for a single action due to `rules:when`'
        )
        expect(json_response['total_warnings']).to eq(1)
      end
    end
  end

  describe 'POST retry.json' do
    subject(:post_retry) do
      post :retry, params: {
        namespace_id: project.namespace, project_id: project, id: pipeline.id
      }, format: :json
    end

    let!(:pipeline) { create(:ci_pipeline, :failed, project: project) }
    let!(:build) { create(:ci_build, :failed, pipeline: pipeline) }

    let(:worker_spy) { class_spy(::Ci::RetryPipelineWorker) }

    before do
      stub_const('::Ci::RetryPipelineWorker', worker_spy)
    end

    it 'retries a pipeline in the background without returning any content' do
      post_retry

      expect(response).to have_gitlab_http_status(:no_content)
      expect(::Ci::RetryPipelineWorker).to have_received(:perform_async).with(pipeline.id, user.id)
    end

    context 'when builds are disabled' do
      let(:feature) { ProjectFeature::DISABLED }

      it 'fails to retry pipeline' do
        post_retry

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when access denied' do
      it 'returns an error' do
        sign_in(create(:user))

        post_retry

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when service returns an error' do
      before do
        service_response = ServiceResponse.error(message: 'some error', http_status: 404)
        allow_next_instance_of(::Ci::RetryPipelineService) do |service|
          allow(service).to receive(:check_access).and_return(service_response)
        end
      end

      it 'does not retry' do
        post_retry

        expect(response).to have_gitlab_http_status(:not_found)
        expect(response.body).to include('some error')
        expect(::Ci::RetryPipelineWorker).not_to have_received(:perform_async).with(pipeline.id, user.id)
      end
    end
  end

  describe 'POST cancel.json' do
    let!(:pipeline) { create(:ci_pipeline, project: project) }
    let!(:job) { create(:ci_build, :running, pipeline: pipeline) }

    subject do
      post :cancel, params: {
        namespace_id: project.namespace, project_id: project, id: pipeline.id
      }, format: :json
    end

    context 'when supports canceling is true' do
      include_context 'when canceling support'

      it 'sets a pipeline status to canceling', :sidekiq_inline do
        subject

        expect(pipeline.reload).to be_canceling
      end

      it 'returns a no content http status' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when supports canceling is false' do
      before do
        allow(job).to receive(:supports_canceling?).and_return(false)
      end

      it 'sets a pipeline status to canceled', :sidekiq_inline do
        subject

        expect(pipeline.reload).to be_canceled
      end

      it 'returns a no content http status' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
      end

      context 'when builds are disabled' do
        let(:feature) { ProjectFeature::DISABLED }

        it 'fails to retry pipeline' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET test_report' do
    let(:pipeline) { create(:ci_pipeline, project: project) }

    it_behaves_like 'the show page', 'test_report'
  end

  describe 'GET test_report.json' do
    let(:pipeline) { create(:ci_pipeline, project: project) }

    context 'with attachments' do
      let(:blob) do
        <<~EOF
          <testsuites>
            <testsuite>
              <testcase classname='Calculator' name='sumTest1' time='0.01'>
                <failure>Some failure</failure>
                <system-out>[[ATTACHMENT|some/path.png]]</system-out>
              </testcase>
            </testsuite>
          </testsuites>
        EOF
      end

      before do
        allow_any_instance_of(Ci::JobArtifact).to receive(:each_blob).and_yield(blob)
      end

      it 'does not have N+1 problem with attachments' do
        get_test_report_json

        create(:ci_build, name: 'rspec', pipeline: pipeline).tap do |build|
          create(:ci_job_artifact, :junit, job: build)
        end

        clear_controller_memoization

        control = ActiveRecord::QueryRecorder.new { get_test_report_json }

        5.times do
          create(:ci_build, name: 'karma', pipeline: pipeline).tap do |build|
            create(:ci_job_artifact, :junit, job: build)
          end
        end

        clear_controller_memoization

        expect { get_test_report_json }.not_to exceed_query_limit(control)
      end
    end

    context 'when pipeline does not have a test report' do
      it 'renders an empty test report' do
        get_test_report_json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['total_count']).to eq(0)
      end
    end

    context 'when pipeline has a test report' do
      before do
        create(:ci_build, :test_reports, name: 'rspec', pipeline: pipeline)
      end

      it 'renders the test report' do
        get_test_report_json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['total_count']).to eq(4)
      end
    end

    context 'when pipeline has a corrupt test report artifact' do
      before do
        create(:ci_build, :broken_test_reports, name: 'rspec', pipeline: pipeline)

        get_test_report_json
      end

      it 'renders the test reports' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['test_suites'].count).to eq(1)
      end

      it 'returns a suite_error on the suite with corrupted XML' do
        expect(json_response['test_suites'].first['suite_error']).to eq('JUnit XML parsing failed: 1:1: FATAL: Document is empty')
      end
    end

    context 'when test_report contains attachment and scope is with_attachment as a URL param' do
      let(:pipeline) { create(:ci_pipeline, :with_test_reports_attachment, project: project) }

      it 'returns a test reports with attachment' do
        get_test_report_json(scope: 'with_attachment')

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response["test_suites"]).to be_present
        expect(json_response["test_suites"].first["test_cases"].first).to include("attachment_url")
      end
    end

    context 'when test_report does not contain attachment and scope is with_attachment as a URL param' do
      let(:pipeline) { create(:ci_pipeline, :with_test_reports, project: project) }

      it 'returns a test reports with empty values' do
        get_test_report_json(scope: 'with_attachment')

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response["test_suites"]).to be_empty
      end
    end

    def get_test_report_json(**args)
      params = {
        namespace_id: project.namespace,
        project_id: project,
        id: pipeline.id
      }

      params.merge!(args) if args

      get :test_report,
        params: params,
        format: :json
    end

    def clear_controller_memoization
      controller.clear_memoization(:pipeline_test_report)
      controller.remove_instance_variable(:@pipeline)
    end
  end

  describe 'GET manual_variables' do
    context 'when FF ci_show_manual_variables_in_pipeline is enabled' do
      let(:pipeline) { create(:ci_pipeline, project: project) }

      it_behaves_like 'the show page', 'manual_variables'
    end

    context 'when FF ci_show_manual_variables_in_pipeline is disabled' do
      let(:pipeline) { create(:ci_pipeline, project: project) }

      before do
        stub_feature_flags(ci_show_manual_variables_in_pipeline: false)
      end

      it 'renders 404' do
        get 'manual_variables', params: { namespace_id: project.namespace, project_id: project, id: pipeline }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET latest' do
    let(:branch_main) { project.repository.branches[0] }
    let(:branch_secondary) { project.repository.branches[1] }

    let!(:pipeline_master) do
      create(:ci_pipeline, ref: branch_main.name, sha: branch_main.target, project: project)
    end

    let!(:pipeline_secondary) do
      create(:ci_pipeline, ref: branch_secondary.name, sha: branch_secondary.target, project: project)
    end

    before do
      project.change_head(branch_main.name)
      project.reload_default_branch
    end

    context 'no ref provided' do
      it 'shows latest pipeline for the default project branch' do
        get :show, params: { namespace_id: project.namespace, project_id: project, latest: true, ref: nil }

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:pipeline)).to have_attributes(id: pipeline_master.id)
      end
    end

    context 'ref provided' do
      render_views

      before do
        create(:ci_pipeline, ref: 'master', project: project)
      end

      it 'shows a 404 if no pipeline exists' do
        get :show, params: { namespace_id: project.namespace, project_id: project, latest: true, ref: 'non-existence' }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'shows the latest pipeline for the provided ref' do
        get :show, params: { namespace_id: project.namespace, project_id: project, latest: true, ref: branch_secondary.name }

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:pipeline)).to have_attributes(id: pipeline_secondary.id)
      end

      context 'newer pipeline exists for older sha' do
        before do
          create(:ci_pipeline, ref: branch_secondary.name, sha: project.commit(branch_secondary.name).parent, project: project)
        end

        it 'shows the provided ref with the last sha/pipeline combo' do
          get :show, params: { namespace_id: project.namespace, project_id: project, latest: true, ref: branch_secondary.name }

          expect(response).to have_gitlab_http_status(:ok)
          expect(assigns(:pipeline)).to have_attributes(id: pipeline_secondary.id)
        end
      end
    end

    it 'renders a 404 if no pipeline is found for the ref' do
      get :show, params: { namespace_id: project.namespace, project_id: project, ref: 'no-branch' }

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'DELETE #destroy' do
    let!(:project) { create(:project, :private, :repository) }
    let!(:pipeline) { create(:ci_pipeline, :failed, project: project) }
    let!(:build) { create(:ci_build, :failed, pipeline: pipeline) }

    context 'when user has ability to delete pipeline' do
      before do
        sign_in(project.first_owner)
      end

      it 'deletes pipeline and redirects' do
        delete_pipeline

        expect(response).to have_gitlab_http_status(:see_other)

        expect(Ci::Build.exists?(build.id)).to be_falsy
        expect(Ci::Pipeline.exists?(pipeline.id)).to be_falsy
      end

      context 'and builds are disabled' do
        let(:feature) { ProjectFeature::DISABLED }

        it 'fails to delete pipeline' do
          delete_pipeline

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'and project is undergoing stats refresh' do
        it_behaves_like 'preventing request because of ongoing project stats refresh' do
          let(:make_request) { delete_pipeline }

          it 'does not delete the pipeline' do
            make_request

            expect(Ci::Pipeline.exists?(pipeline.id)).to be_truthy
          end
        end
      end
    end

    context 'when user has no privileges' do
      it 'fails to delete pipeline' do
        delete_pipeline

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    def delete_pipeline
      delete :destroy, params: {
                         namespace_id: project.namespace,
                         project_id: project,
                         id: pipeline.id
                       }
    end
  end

  describe 'GET downloadable_artifacts.json' do
    context 'when pipeline is empty' do
      let(:pipeline) { create(:ci_empty_pipeline) }

      it 'returns status not_found' do
        get_downloadable_artifacts_json

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when pipeline exists' do
      context 'when pipeline does not have any downloadable artifacts' do
        let(:pipeline) { create(:ci_pipeline, project: project) }

        it 'returns an empty array' do
          get_downloadable_artifacts_json

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['artifacts']).to be_empty
        end
      end

      context 'when pipeline has downloadable artifacts' do
        let(:pipeline) { create(:ci_pipeline, :with_codequality_reports, project: project) }

        before do
          create(:ci_build, name: 'rspec', pipeline: pipeline).tap do |build|
            create(:ci_job_artifact, :junit, job: build)
          end
        end

        it 'returns an array of artifacts' do
          get_downloadable_artifacts_json

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['artifacts']).to be_kind_of(Array)
          expect(json_response['artifacts'].size).to eq(2)
        end
      end
    end

    private

    def get_downloadable_artifacts_json
      get :downloadable_artifacts,
        params: {
          namespace_id: project.namespace,
          project_id: project,
          id: pipeline.id
        },
        format: :json
    end
  end
end
