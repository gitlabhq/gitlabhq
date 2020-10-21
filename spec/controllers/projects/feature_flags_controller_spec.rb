# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::FeatureFlagsController do
  include Gitlab::Routing
  include FeatureFlagHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let(:user) { developer }

  before_all do
    project.add_developer(developer)
    project.add_reporter(reporter)
  end

  before do
    sign_in(user)
  end

  describe 'GET index' do
    render_views

    subject { get(:index, params: view_params) }

    context 'when there is no feature flags' do
      it 'responds with success' do
        is_expected.to have_gitlab_http_status(:ok)
      end
    end

    context 'for a list of feature flags' do
      let!(:feature_flags) { create_list(:operations_feature_flag, 50, project: project) }

      it 'responds with success' do
        is_expected.to have_gitlab_http_status(:ok)
      end
    end

    context 'when the user is a reporter' do
      let(:user) { reporter }

      it 'responds with not found' do
        is_expected.to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #index.json' do
    subject { get(:index, params: view_params, format: :json) }

    let!(:feature_flag_active) do
      create(:operations_feature_flag, project: project, active: true, name: 'feature_flag_a')
    end

    let!(:feature_flag_inactive) do
      create(:operations_feature_flag, project: project, active: false, name: 'feature_flag_b')
    end

    it 'returns all feature flags as json response' do
      subject

      expect(json_response['feature_flags'].count).to eq(2)
      expect(json_response['feature_flags'].first['name']).to eq(feature_flag_active.name)
      expect(json_response['feature_flags'].second['name']).to eq(feature_flag_inactive.name)
    end

    it 'returns CRUD paths' do
      subject

      expected_edit_path = edit_project_feature_flag_path(project, feature_flag_active)
      expected_update_path = project_feature_flag_path(project, feature_flag_active)
      expected_destroy_path = project_feature_flag_path(project, feature_flag_active)

      feature_flag_json = json_response['feature_flags'].first

      expect(feature_flag_json['edit_path']).to eq(expected_edit_path)
      expect(feature_flag_json['update_path']).to eq(expected_update_path)
      expect(feature_flag_json['destroy_path']).to eq(expected_destroy_path)
    end

    it 'returns the summary of feature flags' do
      subject

      expect(json_response['count']['all']).to eq(2)
      expect(json_response['count']['enabled']).to eq(1)
      expect(json_response['count']['disabled']).to eq(1)
    end

    it 'matches json schema' do
      is_expected.to match_response_schema('feature_flags')
    end

    it 'returns false for active when the feature flag is inactive even if it has an active scope' do
      create(:operations_feature_flag_scope,
             feature_flag: feature_flag_inactive,
             environment_scope: 'production',
             active: true)

      subject

      expect(response).to have_gitlab_http_status(:ok)
      feature_flag_json = json_response['feature_flags'].second

      expect(feature_flag_json['active']).to eq(false)
    end

    it 'returns the feature flag iid' do
      subject

      feature_flag_json = json_response['feature_flags'].first

      expect(feature_flag_json['iid']).to eq(feature_flag_active.iid)
    end

    context 'when scope is specified' do
      let(:view_params) do
        { namespace_id: project.namespace, project_id: project, scope: scope }
      end

      context 'when all feature flags are requested' do
        let(:scope) { 'all' }

        it 'returns all feature flags' do
          subject

          expect(json_response['feature_flags'].count).to eq(2)
        end
      end

      context 'when enabled feature flags are requested' do
        let(:scope) { 'enabled' }

        it 'returns enabled feature flags' do
          subject

          expect(json_response['feature_flags'].count).to eq(1)
          expect(json_response['feature_flags'].first['active']).to be_truthy
        end
      end

      context 'when disabled feature flags are requested' do
        let(:scope) { 'disabled' }

        it 'returns disabled feature flags' do
          subject

          expect(json_response['feature_flags'].count).to eq(1)
          expect(json_response['feature_flags'].first['active']).to be_falsy
        end
      end
    end

    context 'when feature flags have additional scopes' do
      let!(:feature_flag_active_scope) do
        create(:operations_feature_flag_scope,
               feature_flag: feature_flag_active,
               environment_scope: 'production',
               active: false)
      end

      let!(:feature_flag_inactive_scope) do
        create(:operations_feature_flag_scope,
               feature_flag: feature_flag_inactive,
               environment_scope: 'staging',
               active: false)
      end

      it 'returns a correct summary' do
        subject

        expect(json_response['count']['all']).to eq(2)
        expect(json_response['count']['enabled']).to eq(1)
        expect(json_response['count']['disabled']).to eq(1)
      end

      it 'recognizes feature flag 1 as active' do
        subject

        expect(json_response['feature_flags'].first['active']).to be_truthy
      end

      it 'recognizes feature flag 2 as inactive' do
        subject

        expect(json_response['feature_flags'].second['active']).to be_falsy
      end

      it 'has ordered scopes' do
        subject

        expect(json_response['feature_flags'][0]['scopes'][0]['id'])
          .to be < json_response['feature_flags'][0]['scopes'][1]['id']
        expect(json_response['feature_flags'][1]['scopes'][0]['id'])
          .to be < json_response['feature_flags'][1]['scopes'][1]['id']
      end

      it 'does not have N+1 problem' do
        recorded = ActiveRecord::QueryRecorder.new { subject }

        related_count = recorded.log
          .count { |query| query.include?('operations_feature_flag') }

        expect(related_count).to be_within(5).of(2)
      end
    end

    context 'with version 1 and 2 feature flags' do
      let!(:new_version_feature_flag) do
        create(:operations_feature_flag, :new_version_flag, project: project, name: 'feature_flag_c')
      end

      it 'returns all feature flags as json response' do
        subject

        expect(json_response['feature_flags'].count).to eq(3)
      end

      it 'returns only version 1 flags when new version flags are disabled' do
        stub_feature_flags(feature_flags_new_version: false)

        subject

        expected = [feature_flag_active.name, feature_flag_inactive.name].sort
        expect(json_response['feature_flags'].map { |f| f['name'] }.sort).to eq(expected)
      end
    end
  end

  describe 'GET new' do
    render_views

    subject { get(:new, params: view_params) }

    it 'renders the form' do
      is_expected.to have_gitlab_http_status(:ok)
    end
  end

  describe 'GET #show.json' do
    subject { get(:show, params: params, format: :json) }

    let!(:feature_flag) do
      create(:operations_feature_flag, project: project)
    end

    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        iid: feature_flag.iid
      }
    end

    it 'returns the feature flag as json response' do
      subject

      expect(json_response['name']).to eq(feature_flag.name)
      expect(json_response['active']).to eq(feature_flag.active)
      expect(json_response['version']).to eq('legacy_flag')
    end

    it 'matches json schema' do
      is_expected.to match_response_schema('feature_flag')
    end

    it 'routes based on iid' do
      other_project = create(:project)
      other_project.add_developer(user)
      other_feature_flag = create(:operations_feature_flag, project: other_project,
                                  name: 'other_flag')
      params = {
        namespace_id: other_project.namespace,
        project_id: other_project,
        iid: other_feature_flag.iid
      }

      get(:show, params: params, format: :json)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['name']).to eq(other_feature_flag.name)
    end

    it 'routes based on iid when new version flags are disabled' do
      stub_feature_flags(feature_flags_new_version: false)
      other_project = create(:project)
      other_project.add_developer(user)
      other_feature_flag = create(:operations_feature_flag, project: other_project,
                                  name: 'other_flag')
      params = {
        namespace_id: other_project.namespace,
        project_id: other_project,
        iid: other_feature_flag.iid
      }

      get(:show, params: params, format: :json)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['name']).to eq(other_feature_flag.name)
    end

    context 'when feature flag is not found' do
      let!(:feature_flag) { }

      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          iid: 1
        }
      end

      it 'returns 404' do
        is_expected.to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is reporter' do
      let(:user) { reporter }

      it 'returns 404' do
        is_expected.to have_gitlab_http_status(:not_found)
      end
    end

    context 'when feature flags have additional scopes' do
      context 'when there is at least one active scope' do
        let!(:feature_flag) do
          create(:operations_feature_flag, project: project, active: false)
        end

        let!(:feature_flag_scope_production) do
          create(:operations_feature_flag_scope,
                feature_flag: feature_flag,
                environment_scope: 'review/*',
                active: true)
        end

        it 'returns false for active' do
          subject

          expect(json_response['active']).to eq(false)
        end
      end

      context 'when all scopes are inactive' do
        let!(:feature_flag) do
          create(:operations_feature_flag, project: project, active: false)
        end

        let!(:feature_flag_scope_production) do
          create(:operations_feature_flag_scope,
                feature_flag: feature_flag,
                environment_scope: 'production',
                active: false)
        end

        it 'recognizes the feature flag as inactive' do
          subject

          expect(json_response['active']).to be_falsy
        end
      end
    end

    context 'with a version 2 feature flag' do
      let!(:new_version_feature_flag) do
        create(:operations_feature_flag, :new_version_flag, project: project)
      end

      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          iid: new_version_feature_flag.iid
        }
      end

      it 'returns the feature flag' do
        subject

        expect(json_response['name']).to eq(new_version_feature_flag.name)
        expect(json_response['active']).to eq(new_version_feature_flag.active)
        expect(json_response['version']).to eq('new_version_flag')
      end

      it 'returns a 404 when new version flags are disabled' do
        stub_feature_flags(feature_flags_new_version: false)

        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns strategies ordered by id' do
        first_strategy = create(:operations_strategy, feature_flag: new_version_feature_flag)
        second_strategy = create(:operations_strategy, feature_flag: new_version_feature_flag)

        subject

        expect(json_response['strategies'].map { |s| s['id'] }).to eq([first_strategy.id, second_strategy.id])
      end
    end
  end

  describe 'POST create.json' do
    subject { post(:create, params: params, format: :json) }

    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        operations_feature_flag: {
          name: 'my_feature_flag',
          active: true
        }
      }
    end

    it 'returns 200' do
      is_expected.to have_gitlab_http_status(:ok)
    end

    it 'creates a new feature flag' do
      subject

      expect(json_response['name']).to eq('my_feature_flag')
      expect(json_response['active']).to be_truthy
    end

    it 'creates a default scope' do
      subject

      expect(json_response['scopes'].count).to eq(1)
      expect(json_response['scopes'].first['environment_scope']).to eq('*')
      expect(json_response['scopes'].first['active']).to be_truthy
    end

    it 'matches json schema' do
      is_expected.to match_response_schema('feature_flag')
    end

    context 'when the same named feature flag has already existed' do
      before do
        create(:operations_feature_flag, name: 'my_feature_flag', project: project)
      end

      it 'returns 400' do
        is_expected.to have_gitlab_http_status(:bad_request)
      end

      it 'returns an error message' do
        subject

        expect(json_response['message']).to include('Name has already been taken')
      end
    end

    context 'without the active parameter' do
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          operations_feature_flag: {
            name: 'my_feature_flag'
          }
        }
      end

      it 'creates a flag with active set to true' do
        expect { subject }.to change { Operations::FeatureFlag.count }.by(1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('feature_flag')
        expect(json_response['active']).to eq(true)
        expect(Operations::FeatureFlag.last.active).to eq(true)
      end
    end

    context 'when user is reporter' do
      let(:user) { reporter }

      it 'returns 404' do
        is_expected.to have_gitlab_http_status(:not_found)
      end
    end

    context 'when creates additional scope' do
      let(:params) do
        view_params.merge({
          operations_feature_flag: {
            name: 'my_feature_flag',
            active: true,
            scopes_attributes: [{ environment_scope: '*', active: true },
                                { environment_scope: 'production', active: false }]
          }
        })
      end

      it 'creates feature flag scopes successfully' do
        expect { subject }.to change { Operations::FeatureFlagScope.count }.by(2)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'creates feature flag scopes in a correct order' do
        subject

        expect(json_response['scopes'].first['environment_scope']).to eq('*')
        expect(json_response['scopes'].second['environment_scope']).to eq('production')
      end

      context 'when default scope is not placed first' do
        let(:params) do
          view_params.merge({
            operations_feature_flag: {
              name: 'my_feature_flag',
              active: true,
              scopes_attributes: [{ environment_scope: 'production', active: false },
                                  { environment_scope: '*', active: true }]
            }
          })
        end

        it 'returns 400' do
          subject

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message'])
            .to include('Default scope has to be the first element')
        end
      end
    end

    context 'when creates additional scope with a percentage rollout' do
      it 'creates a strategy for the scope' do
        params = view_params.merge({
          operations_feature_flag: {
            name: 'my_feature_flag',
            active: true,
            scopes_attributes: [{ environment_scope: '*', active: true },
                                { environment_scope: 'production', active: false,
                                  strategies: [{ name: 'gradualRolloutUserId',
                                                 parameters: { groupId: 'default', percentage: '42' } }] }]
          }
        })

        post(:create, params: params, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        production_strategies_json = json_response['scopes'].second['strategies']
        expect(production_strategies_json).to eq([{
          'name' => 'gradualRolloutUserId',
          'parameters' => { "groupId" => "default", "percentage" => "42" }
        }])
      end
    end

    context 'when creates additional scope with a userWithId strategy' do
      it 'creates a strategy for the scope' do
        params = view_params.merge({
          operations_feature_flag: {
            name: 'my_feature_flag',
            active: true,
            scopes_attributes: [{ environment_scope: '*', active: true },
                                { environment_scope: 'production', active: false,
                                  strategies: [{ name: 'userWithId',
                                                 parameters: { userIds: '123,4,6722' } }] }]
          }
        })

        post(:create, params: params, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        production_strategies_json = json_response['scopes'].second['strategies']
        expect(production_strategies_json).to eq([{
          'name' => 'userWithId',
          'parameters' => { "userIds" => "123,4,6722" }
        }])
      end
    end

    context 'when creates an additional scope without a strategy' do
      it 'creates a default strategy' do
        params = view_params.merge({
          operations_feature_flag: {
            name: 'my_feature_flag',
            active: true,
            scopes_attributes: [{ environment_scope: '*', active: true }]
          }
        })

        post(:create, params: params, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        default_strategies_json = json_response['scopes'].first['strategies']
        expect(default_strategies_json).to eq([{ "name" => "default", "parameters" => {} }])
      end
    end

    context 'when creating a version 2 feature flag' do
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          operations_feature_flag: {
            name: 'my_feature_flag',
            active: true,
            version: 'new_version_flag'
          }
        }
      end

      it 'creates a new feature flag' do
        subject

        expect(json_response['name']).to eq('my_feature_flag')
        expect(json_response['active']).to be_truthy
        expect(json_response['version']).to eq('new_version_flag')
      end
    end

    context 'when creating a version 2 feature flag with strategies and scopes' do
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          operations_feature_flag: {
            name: 'my_feature_flag',
            active: true,
            version: 'new_version_flag',
            strategies_attributes: [{
              name: 'userWithId',
              parameters: { userIds: 'user1' },
              scopes_attributes: [{ environment_scope: '*' }]
            }]
          }
        }
      end

      it 'creates a new feature flag with the strategies and scopes' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq('my_feature_flag')
        expect(json_response['active']).to eq(true)
        expect(json_response['strategies'].count).to eq(1)

        strategy_json = json_response['strategies'].first
        expect(strategy_json).to have_key('id')
        expect(strategy_json['name']).to eq('userWithId')
        expect(strategy_json['parameters']).to eq({ 'userIds' => 'user1' })
        expect(strategy_json['scopes'].count).to eq(1)

        scope_json = strategy_json['scopes'].first
        expect(scope_json).to have_key('id')
        expect(scope_json['environment_scope']).to eq('*')
      end
    end

    context 'when creating a version 2 feature flag with a gradualRolloutUserId strategy' do
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          operations_feature_flag: {
            name: 'my_feature_flag',
            active: true,
            version: 'new_version_flag',
            strategies_attributes: [{
              name: 'gradualRolloutUserId',
              parameters: { groupId: 'default', percentage: '15' },
              scopes_attributes: [{ environment_scope: 'production' }]
            }]
          }
        }
      end

      it 'creates the new strategy' do
        subject

        expect(response).to have_gitlab_http_status(:ok)

        strategy_json = json_response['strategies'].first
        expect(strategy_json['name']).to eq('gradualRolloutUserId')
        expect(strategy_json['parameters']).to eq({ 'groupId' => 'default', 'percentage' => '15' })
        expect(strategy_json['scopes'].count).to eq(1)

        scope_json = strategy_json['scopes'].first
        expect(scope_json['environment_scope']).to eq('production')
      end
    end

    context 'when creating a version 2 feature flag with a flexibleRollout strategy' do
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          operations_feature_flag: {
            name: 'my_feature_flag',
            active: true,
            version: 'new_version_flag',
            strategies_attributes: [{
              name: 'flexibleRollout',
              parameters: { groupId: 'default', rollout: '15', stickiness: 'DEFAULT' },
              scopes_attributes: [{ environment_scope: 'production' }]
            }]
          }
        }
      end

      it 'creates the new strategy' do
        subject

        expect(response).to have_gitlab_http_status(:ok)

        strategy_json = json_response['strategies'].first
        expect(strategy_json['name']).to eq('flexibleRollout')
        expect(strategy_json['parameters']).to eq({ 'groupId' => 'default', 'rollout' => '15', 'stickiness' => 'DEFAULT' })
        expect(strategy_json['scopes'].count).to eq(1)

        scope_json = strategy_json['scopes'].first
        expect(scope_json['environment_scope']).to eq('production')
      end
    end

    context 'when creating a version 2 feature flag with a gitlabUserList strategy' do
      let!(:user_list) do
        create(:operations_feature_flag_user_list, project: project,
               name: 'My List', user_xids: 'user1,user2')
      end

      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          operations_feature_flag: {
            name: 'my_feature_flag',
            active: true,
            version: 'new_version_flag',
            strategies_attributes: [{
              name: 'gitlabUserList',
              parameters: {},
              user_list_id: user_list.id,
              scopes_attributes: [{ environment_scope: 'production' }]
            }]
          }
        }
      end

      it 'creates the new strategy' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['strategies']).to match([a_hash_including({
          'name' => 'gitlabUserList',
          'parameters' => {},
          'user_list' => {
            'id' => user_list.id,
            'iid' => user_list.iid,
            'name' => 'My List',
            'user_xids' => 'user1,user2'
          },
          'scopes' => [a_hash_including({
            'environment_scope' => 'production'
          })]
        })])
      end
    end

    context 'when version parameter is invalid' do
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          operations_feature_flag: {
            name: 'my_feature_flag',
            active: true,
            version: 'bad_version'
          }
        }
      end

      it 'returns a 400' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'message' => 'Version is invalid' })
        expect(Operations::FeatureFlag.count).to eq(0)
      end
    end

    context 'when version 2 flags are disabled' do
      context 'and attempting to create a version 2 flag' do
        let(:params) do
          {
            namespace_id: project.namespace,
            project_id: project,
            operations_feature_flag: {
              name: 'my_feature_flag',
              active: true,
              version: 'new_version_flag'
            }
          }
        end

        it 'returns a 400' do
          stub_feature_flags(feature_flags_new_version: false)

          subject

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(Operations::FeatureFlag.count).to eq(0)
        end
      end

      context 'and attempting to create a version 1 flag' do
        let(:params) do
          {
            namespace_id: project.namespace,
            project_id: project,
            operations_feature_flag: {
              name: 'my_feature_flag',
              active: true
            }
          }
        end

        it 'creates the flag' do
          stub_feature_flags(feature_flags_new_version: false)

          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(Operations::FeatureFlag.count).to eq(1)
          expect(json_response['version']).to eq('legacy_flag')
        end
      end
    end
  end

  describe 'DELETE destroy.json' do
    subject { delete(:destroy, params: params, format: :json) }

    let!(:feature_flag) { create(:operations_feature_flag, project: project) }

    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        iid: feature_flag.iid
      }
    end

    it 'returns 200' do
      is_expected.to have_gitlab_http_status(:ok)
    end

    it 'deletes one feature flag' do
      expect { subject }.to change { Operations::FeatureFlag.count }.by(-1)
    end

    it 'destroys the default scope' do
      expect { subject }.to change { Operations::FeatureFlagScope.count }.by(-1)
    end

    it 'matches json schema' do
      is_expected.to match_response_schema('feature_flag')
    end

    context 'when user is reporter' do
      let(:user) { reporter }

      it 'returns 404' do
        is_expected.to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the feature flag does not exist' do
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          iid: 0
        }
      end

      it 'returns not found' do
        is_expected.to have_gitlab_http_status(:not_found)
      end
    end

    context 'when there is an additional scope' do
      let!(:scope) { create_scope(feature_flag, 'production', false) }

      it 'destroys the default scope and production scope' do
        expect { subject }.to change { Operations::FeatureFlagScope.count }.by(-2)
      end
    end

    context 'with a version 2 flag' do
      let!(:new_version_flag) { create(:operations_feature_flag, :new_version_flag, project: project) }
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          iid: new_version_flag.iid
        }
      end

      it 'deletes the flag' do
        expect { subject }.to change { Operations::FeatureFlag.count }.by(-1)
      end

      context 'when new version flags are disabled' do
        it 'returns a 404' do
          stub_feature_flags(feature_flags_new_version: false)

          expect { subject }.not_to change { Operations::FeatureFlag.count }
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'PUT update.json' do
    def put_request(feature_flag, feature_flag_params)
      params = {
        namespace_id: project.namespace,
        project_id: project,
        iid: feature_flag.iid,
        operations_feature_flag: feature_flag_params
      }

      put(:update, params: params, format: :json, as: :json)
    end

    before do
      stub_feature_flags(
        feature_flags_legacy_read_only: false,
        feature_flags_legacy_read_only_override: false
      )
    end

    subject { put(:update, params: params, format: :json) }

    let!(:feature_flag) do
      create(:operations_feature_flag,
             :legacy_flag,
             name: 'ci_live_trace',
             active: true,
             project: project)
    end

    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        iid: feature_flag.iid,
        operations_feature_flag: {
          name: 'ci_new_live_trace'
        }
      }
    end

    it 'returns 200' do
      is_expected.to have_gitlab_http_status(:ok)
    end

    it 'updates the name of the feature flag name' do
      subject

      expect(json_response['name']).to eq('ci_new_live_trace')
    end

    it 'matches json schema' do
      is_expected.to match_response_schema('feature_flag')
    end

    context 'when updates active' do
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          iid: feature_flag.iid,
          operations_feature_flag: {
            active: false
          }
        }
      end

      it 'updates active from true to false' do
        expect { subject }
          .to change { feature_flag.reload.active }.from(true).to(false)
      end

      it "does not change default scope's active" do
        expect { subject }
          .not_to change { feature_flag.default_scope.reload.active }.from(true)
      end

      it 'updates active from false to true when an inactive feature flag has an active scope' do
        feature_flag = create(:operations_feature_flag, project: project, name: 'my_flag', active: false)
        create(:operations_feature_flag_scope, feature_flag: feature_flag, environment_scope: 'production', active: true)

        put_request(feature_flag, { active: true })

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('feature_flag')
        expect(json_response['active']).to eq(true)
        expect(feature_flag.reload.active).to eq(true)
        expect(feature_flag.default_scope.reload.active).to eq(false)
      end
    end

    context 'when user is reporter' do
      let(:user) { reporter }

      it 'returns 404' do
        is_expected.to have_gitlab_http_status(:not_found)
      end
    end

    context "when creates an additional scope for production environment" do
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          iid: feature_flag.iid,
          operations_feature_flag: {
            scopes_attributes: [{ environment_scope: 'production', active: false }]
          }
        }
      end

      it 'creates a production scope' do
        expect { subject }.to change { feature_flag.reload.scopes.count }.by(1)

        expect(json_response['scopes'].last['environment_scope']).to eq('production')
        expect(json_response['scopes'].last['active']).to be_falsy
      end
    end

    context "when creates a default scope" do
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          iid: feature_flag.iid,
          operations_feature_flag: {
            scopes_attributes: [{ environment_scope: '*', active: false }]
          }
        }
      end

      it 'returns 400' do
        is_expected.to have_gitlab_http_status(:bad_request)
      end
    end

    context "when updates a default scope's active value" do
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          iid: feature_flag.iid,
          operations_feature_flag: {
            scopes_attributes: [
              {
                id: feature_flag.default_scope.id,
                environment_scope: '*',
                active: false
              }
            ]
          }
        }
      end

      it "updates successfully" do
        subject

        expect(json_response['scopes'].first['environment_scope']).to eq('*')
        expect(json_response['scopes'].first['active']).to be_falsy
      end
    end

    context "when changes default scope's spec" do
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          iid: feature_flag.iid,
          operations_feature_flag: {
            scopes_attributes: [
              {
                id: feature_flag.default_scope.id,
                environment_scope: 'review/*'
              }
            ]
          }
        }
      end

      it 'returns 400' do
        is_expected.to have_gitlab_http_status(:bad_request)
      end
    end

    context "when destroys the default scope" do
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          iid: feature_flag.iid,
          operations_feature_flag: {
            scopes_attributes: [
              {
                id: feature_flag.default_scope.id,
                _destroy: 1
              }
            ]
          }
        }
      end

      it 'raises an error' do
        expect { subject }.to raise_error(ActiveRecord::ReadOnlyRecord)
      end
    end

    context "when destroys a production scope" do
      let!(:production_scope) { create_scope(feature_flag, 'production', true) }
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          iid: feature_flag.iid,
          operations_feature_flag: {
            scopes_attributes: [
              {
                id: production_scope.id,
                _destroy: 1
              }
            ]
          }
        }
      end

      it 'destroys successfully' do
        subject

        scopes = json_response['scopes']
        expect(scopes.any? { |scope| scope['environment_scope'] == 'production' })
          .to be_falsy
      end
    end

    describe "updating the strategy" do
      it 'creates a default strategy' do
        scope = create_scope(feature_flag, 'production', true, [])

        put_request(feature_flag, scopes_attributes: [{
          id: scope.id,
          strategies: [{ name: 'default', parameters: {} }]
        }])

        expect(response).to have_gitlab_http_status(:ok)
        scope_json = json_response['scopes'].find do |s|
          s['environment_scope'] == 'production'
        end
        expect(scope_json['strategies']).to eq([{
          "name" => "default",
          "parameters" => {}
        }])
      end

      it 'creates a gradualRolloutUserId strategy' do
        scope = create_scope(feature_flag, 'production', true, [])

        put_request(feature_flag, scopes_attributes: [{
          id: scope.id,
          strategies: [{ name: 'gradualRolloutUserId',
                         parameters: { groupId: 'default', percentage: "70" } }]
        }])

        expect(response).to have_gitlab_http_status(:ok)
        scope_json = json_response['scopes'].find do |s|
          s['environment_scope'] == 'production'
        end
        expect(scope_json['strategies']).to eq([{
          "name" => "gradualRolloutUserId",
          "parameters" => {
            "groupId" => "default",
            "percentage" => "70"
          }
        }])
      end

      it 'creates a userWithId strategy' do
        scope = create_scope(feature_flag, 'production', true, [{ name: 'default', parameters: {} }])

        put_request(feature_flag, scopes_attributes: [{
          id: scope.id,
          strategies: [{ name: 'userWithId', parameters: { userIds: 'sam,fred' } }]
        }])

        expect(response).to have_gitlab_http_status(:ok)
        scope_json = json_response['scopes'].find do |s|
          s['environment_scope'] == 'production'
        end
        expect(scope_json['strategies']).to eq([{
          "name" => "userWithId",
          "parameters" => { "userIds" => "sam,fred" }
        }])
      end

      it 'updates an existing strategy' do
        scope = create_scope(feature_flag, 'production', true, [{ name: 'default', parameters: {} }])

        put_request(feature_flag, scopes_attributes: [{
          id: scope.id,
          strategies: [{ name: 'gradualRolloutUserId',
                         parameters: { groupId: 'default', percentage: "50" } }]
        }])

        expect(response).to have_gitlab_http_status(:ok)
        scope_json = json_response['scopes'].find do |s|
          s['environment_scope'] == 'production'
        end
        expect(scope_json['strategies']).to eq([{
          "name" => "gradualRolloutUserId",
          "parameters" => {
            "groupId" => "default",
            "percentage" => "50"
          }
        }])
      end

      it 'clears an existing strategy' do
        scope = create_scope(feature_flag, 'production', true, [{ name: 'default', parameters: {} }])

        put_request(feature_flag, scopes_attributes: [{
          id: scope.id,
          strategies: []
        }])

        expect(response).to have_gitlab_http_status(:ok)
        scope_json = json_response['scopes'].find do |s|
          s['environment_scope'] == 'production'
        end
        expect(scope_json['strategies']).to eq([])
      end

      it 'accepts multiple strategies' do
        scope = create_scope(feature_flag, 'production', true, [{ name: 'default', parameters: {} }])

        put_request(feature_flag, scopes_attributes: [{
          id: scope.id,
          strategies: [
            { name: 'gradualRolloutUserId', parameters: { groupId: 'mygroup', percentage: '55' } },
            { name: 'userWithId', parameters: { userIds: 'joe' } }
          ]
        }])

        expect(response).to have_gitlab_http_status(:ok)
        scope_json = json_response['scopes'].find do |s|
          s['environment_scope'] == 'production'
        end
        expect(scope_json['strategies'].length).to eq(2)
        expect(scope_json['strategies']).to include({
          "name" => "gradualRolloutUserId",
          "parameters" => { "groupId" => "mygroup", "percentage" => "55" }
        })
        expect(scope_json['strategies']).to include({
          "name" => "userWithId",
          "parameters" => { "userIds" => "joe" }
        })
      end

      it 'does not modify strategies when there is no strategies key in the params' do
        scope = create_scope(feature_flag, 'production', true, [{ name: 'default', parameters: {} }])

        put_request(feature_flag, scopes_attributes: [{ id: scope.id }])

        expect(response).to have_gitlab_http_status(:ok)
        scope_json = json_response['scopes'].find do |s|
          s['environment_scope'] == 'production'
        end
        expect(scope_json['strategies']).to eq([{
          "name" => "default",
          "parameters" => {}
        }])
      end

      it 'leaves an existing strategy when there are no strategies in the params' do
        scope = create_scope(feature_flag, 'production', true, [{ name: 'gradualRolloutUserId',
                                                                  parameters: { groupId: 'default', percentage: '10' } }])

        put_request(feature_flag, scopes_attributes: [{ id: scope.id }])

        expect(response).to have_gitlab_http_status(:ok)
        scope_json = json_response['scopes'].find do |s|
          s['environment_scope'] == 'production'
        end
        expect(scope_json['strategies']).to eq([{
          "name" => "gradualRolloutUserId",
          "parameters" => { "groupId" => "default", "percentage" => "10" }
        }])
      end

      it 'does not accept extra parameters in the strategy params' do
        scope = create_scope(feature_flag, 'production', true, [{ name: 'default', parameters: {} }])

        put_request(feature_flag, scopes_attributes: [{
          id: scope.id,
          strategies: [{ name: 'userWithId', parameters: { userIds: 'joe', groupId: 'default' } }]
        }])

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq(["Scopes strategies parameters are invalid"])
      end
    end

    context 'when legacy feature flags are set to be read only' do
      it 'does not update the flag' do
        stub_feature_flags(feature_flags_legacy_read_only: true)

        put_request(feature_flag, name: 'ci_new_live_trace')

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq(["Legacy feature flags are read-only"])
      end

      it 'updates the flag if the legacy read-only override is enabled for a particular project' do
        stub_feature_flags(
          feature_flags_legacy_read_only: true,
          feature_flags_legacy_read_only_override: project
        )

        put_request(feature_flag, name: 'ci_new_live_trace')

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq('ci_new_live_trace')
      end
    end

    context 'with a version 2 feature flag' do
      let!(:new_version_flag) do
        create(:operations_feature_flag,
               :new_version_flag,
               name: 'new-feature',
               active: true,
               project: project)
      end

      it 'creates a new strategy and scope' do
        put_request(new_version_flag, strategies_attributes: [{
          name: 'userWithId',
          parameters: { userIds: 'user1' },
          scopes_attributes: [{
            environment_scope: 'production'
          }]
        }])

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['strategies'].count).to eq(1)
        strategy_json = json_response['strategies'].first
        expect(strategy_json['name']).to eq('userWithId')
        expect(strategy_json['parameters']).to eq({
          'userIds' => 'user1'
        })
        expect(strategy_json['scopes'].count).to eq(1)
        scope_json = strategy_json['scopes'].first
        expect(scope_json['environment_scope']).to eq('production')
      end

      it 'creates a gradualRolloutUserId strategy' do
        put_request(new_version_flag, strategies_attributes: [{
          name: 'gradualRolloutUserId',
          parameters: { groupId: 'default', percentage: '30' }
        }])

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['strategies'].count).to eq(1)
        strategy_json = json_response['strategies'].first
        expect(strategy_json['name']).to eq('gradualRolloutUserId')
        expect(strategy_json['parameters']).to eq({
          'groupId' => 'default',
          'percentage' => '30'
        })
        expect(strategy_json['scopes']).to eq([])
      end

      it 'creates a flexibleRollout strategy' do
        put_request(new_version_flag, strategies_attributes: [{
          name: 'flexibleRollout',
          parameters: { groupId: 'default', rollout: '30', stickiness: 'DEFAULT' }
        }])

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['strategies'].count).to eq(1)
        strategy_json = json_response['strategies'].first
        expect(strategy_json['name']).to eq('flexibleRollout')
        expect(strategy_json['parameters']).to eq({
          'groupId' => 'default',
          'rollout' => '30',
          'stickiness' => 'DEFAULT'
        })
        expect(strategy_json['scopes']).to eq([])
      end

      it 'creates a gitlabUserList strategy' do
        user_list = create(:operations_feature_flag_user_list, project: project, name: 'My List', user_xids: 'user1,user2')

        put_request(new_version_flag, strategies_attributes: [{
          name: 'gitlabUserList',
          parameters: {},
          user_list_id: user_list.id
        }])

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['strategies']).to match([a_hash_including({
          'id' => an_instance_of(Integer),
          'name' => 'gitlabUserList',
          'parameters' => {},
          'user_list' => {
            'id' => user_list.id,
            'iid' => user_list.iid,
            'name' => 'My List',
            'user_xids' => 'user1,user2'
          },
          'scopes' => []
        })])
      end

      it 'supports switching the associated user list for an existing gitlabUserList strategy' do
        user_list = create(:operations_feature_flag_user_list, project: project, name: 'My List', user_xids: 'user1,user2')
        strategy = create(:operations_strategy, feature_flag: new_version_flag, name: 'gitlabUserList', parameters: {}, user_list: user_list)
        other_user_list = create(:operations_feature_flag_user_list, project: project, name: 'Other List', user_xids: 'user3')

        put_request(new_version_flag, strategies_attributes: [{
          id: strategy.id,
          user_list_id: other_user_list.id
        }])

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['strategies']).to eq([{
          'id' => strategy.id,
          'name' => 'gitlabUserList',
          'parameters' => {},
          'user_list' => {
            'id' => other_user_list.id,
            'iid' => other_user_list.iid,
            'name' => 'Other List',
            'user_xids' => 'user3'
          },
          'scopes' => []
        }])
      end

      it 'automatically dissociates the user list when switching the type of an existing gitlabUserList strategy' do
        user_list = create(:operations_feature_flag_user_list, project: project, name: 'My List', user_xids: 'user1,user2')
        strategy = create(:operations_strategy, feature_flag: new_version_flag, name: 'gitlabUserList', parameters: {}, user_list: user_list)

        put_request(new_version_flag, strategies_attributes: [{
          id: strategy.id,
          name: 'gradualRolloutUserId',
          parameters: {
            groupId: 'default',
            percentage: '25'
          }
        }])

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['strategies']).to eq([{
          'id' => strategy.id,
          'name' => 'gradualRolloutUserId',
          'parameters' => {
            'groupId' => 'default',
            'percentage' => '25'
          },
          'scopes' => []
        }])
      end

      it 'does not delete a user list when deleting a gitlabUserList strategy' do
        user_list = create(:operations_feature_flag_user_list, project: project, name: 'My List', user_xids: 'user1,user2')
        strategy = create(:operations_strategy, feature_flag: new_version_flag, name: 'gitlabUserList', parameters: {}, user_list: user_list)

        put_request(new_version_flag, strategies_attributes: [{
          id: strategy.id,
          _destroy: true
        }])

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['strategies']).to eq([])
        expect(::Operations::FeatureFlags::Strategy.count).to eq(0)
        expect(::Operations::FeatureFlags::StrategyUserList.count).to eq(0)
        expect(::Operations::FeatureFlags::UserList.first).to eq(user_list)
      end

      it 'returns not found when trying to create a gitlabUserList strategy with an invalid user list id' do
        put_request(new_version_flag, strategies_attributes: [{
          name: 'gitlabUserList',
          parameters: {},
          user_list_id: 1
        }])

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'updates an existing strategy' do
        strategy = create(:operations_strategy, feature_flag: new_version_flag, name: 'default', parameters: {})

        put_request(new_version_flag, strategies_attributes: [{
          id: strategy.id,
          name: 'userWithId',
          parameters: { userIds: 'user2,user3' }
        }])

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['strategies']).to eq([{
          'id' => strategy.id,
          'name' => 'userWithId',
          'parameters' => { 'userIds' => 'user2,user3' },
          'scopes' => []
        }])
      end

      it 'updates an existing scope' do
        strategy = create(:operations_strategy, feature_flag: new_version_flag, name: 'default', parameters: {})
        scope = create(:operations_scope, strategy: strategy, environment_scope: 'staging')

        put_request(new_version_flag, strategies_attributes: [{
          id: strategy.id,
          scopes_attributes: [{
            id: scope.id,
            environment_scope: 'sandbox'
          }]
        }])

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['strategies'].first['scopes']).to eq([{
          'id' => scope.id,
          'environment_scope' => 'sandbox'
        }])
      end

      it 'deletes an existing strategy' do
        strategy = create(:operations_strategy, feature_flag: new_version_flag, name: 'default', parameters: {})

        put_request(new_version_flag, strategies_attributes: [{
          id: strategy.id,
          _destroy: true
        }])

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['strategies']).to eq([])
      end

      it 'deletes an existing scope' do
        strategy = create(:operations_strategy, feature_flag: new_version_flag, name: 'default', parameters: {})
        scope = create(:operations_scope, strategy: strategy, environment_scope: 'staging')

        put_request(new_version_flag, strategies_attributes: [{
          id: strategy.id,
          scopes_attributes: [{
            id: scope.id,
            _destroy: true
          }]
        }])

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['strategies'].first['scopes']).to eq([])
      end

      it 'does not update the flag if version 2 flags are disabled' do
        stub_feature_flags(feature_flags_new_version: false)

        put_request(new_version_flag, { name: 'some-other-name' })

        expect(response).to have_gitlab_http_status(:not_found)
        expect(new_version_flag.reload.name).to eq('new-feature')
      end

      it 'updates the flag when legacy feature flags are set to be read only' do
        stub_feature_flags(feature_flags_legacy_read_only: true)

        put_request(new_version_flag, name: 'some-other-name')

        expect(response).to have_gitlab_http_status(:ok)
        expect(new_version_flag.reload.name).to eq('some-other-name')
      end
    end
  end

  private

  def view_params
    { namespace_id: project.namespace, project_id: project }
  end
end
