require 'spec_helper'

describe API::V3::Github do
  let(:user) { create(:user) }
  let!(:project) { create(:project, :repository, creator: user) }

  before do
    allow(Gitlab::Jira::Middleware).to receive(:jira_dvcs_connector?) { true }
    project.add_master(user)
  end

  describe 'GET /orgs/:namespace/repos' do
    it 'returns an empty array' do
      group = create(:group)

      get v3_api("/orgs/#{group.path}/repos", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to eq([])
    end
  end

  describe 'GET /user/repos' do
    it 'returns an empty array' do
      get v3_api('/user/repos', user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to eq([])
    end
  end

  describe 'GET /-/jira/pulls' do
    let(:assignee) { create(:user) }
    let!(:merge_request) do
      create(:merge_request, source_project: project, target_project: project, author: user, assignee: assignee)
    end

    it 'returns an array of merge requests with github format' do
      stub_licensed_features(jira_dev_panel_integration: true)

      get v3_api('/repos/-/jira/pulls', user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an(Array)
      expect(json_response.size).to eq(1)
      expect(response).to match_response_schema('entities/github/pull_requests', dir: 'ee')
    end
  end

  describe 'GET /-/jira/issues/:id/comments' do
    context 'when user has access to the merge request' do
      let(:merge_request) do
        create(:merge_request, source_project: project, target_project: project)
      end
      let!(:note) do
        create(:note, project: project, noteable: merge_request)
      end

      it 'returns an array of notes' do
        stub_licensed_features(jira_dev_panel_integration: true)

        get v3_api("/repos/-/jira/issues/#{merge_request.id}/comments", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(1)
      end
    end

    context 'when user has no access to the merge request' do
      let(:private_project) { create(:project, :private) }
      let(:merge_request) do
        create(:merge_request, source_project: private_project, target_project: private_project)
      end
      let!(:note) do
        create(:note, project: private_project, noteable: merge_request)
      end

      before do
        private_project.add_guest(user)
      end

      it 'returns 404' do
        stub_licensed_features(jira_dev_panel_integration: true)

        get v3_api("/repos/-/jira/issues/#{merge_request.id}/comments", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET /-/jira/pulls/:id/commits' do
    it 'returns an empty array' do
      get v3_api("/repos/-/jira/pulls/xpto/commits", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to eq([])
    end
  end

  describe 'GET /-/jira/pulls/:id/comments' do
    it 'returns an empty array' do
      get v3_api("/repos/-/jira/pulls/xpto/comments", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to eq([])
    end
  end

  describe 'GET /users/:namespace/repos' do
    context 'authenticated' do
      let(:group) { create(:group) }
      let!(:group_project) { create(:project, group: group) }

      before do
        stub_licensed_features(jira_dev_panel_integration: true)
        group.add_master(user)

        get v3_api('/users/foo/repos', user)
      end

      it 'returns an array of projects with github format' do
        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(2)

        expect(response).to match_response_schema('entities/github/repositories', dir: 'ee')
      end

      it 'returns valid project path as name' do
        project_names = json_response.map { |r| r['name'] }

        expect(project_names).to include(project.path, group_project.path)
      end
    end

    context 'unauthenticated' do
      it 'returns 401' do
        get v3_api("/users/foo/repos", nil)

        expect(response).to have_gitlab_http_status(401)
      end
    end

    it 'filters unlicensed namespace projects' do
      silver_plan = create(:silver_plan)
      licensed_project = create(:project, :empty_repo)
      licensed_project.add_reporter(user)
      licensed_project.namespace.update!(plan_id: silver_plan.id)

      stub_licensed_features(jira_dev_panel_integration: true)
      stub_application_setting_on_object(project, should_check_namespace_plan: true)
      stub_application_setting_on_object(licensed_project, should_check_namespace_plan: true)

      get v3_api('/users/foo/repos', user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response.size).to eq(1)
      expect(json_response.first['id']).to eq(licensed_project.id)
    end
  end

  describe 'GET /repos/:namespace/:project/branches' do
    context 'authenticated' do
      it 'returns an array of project branches with github format' do
        stub_licensed_features(jira_dev_panel_integration: true)

        get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)

        expect(response).to match_response_schema('entities/github/branches', dir: 'ee')
      end
    end

    context 'unauthenticated' do
      it 'returns 401' do
        stub_licensed_features(jira_dev_panel_integration: true)

        get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", nil)

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'unauthorized' do
      it 'returns 404 when not licensed' do
        stub_licensed_features(jira_dev_panel_integration: false)
        unauthorized_user = create(:user)
        project.add_reporter(unauthorized_user)

        get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", unauthorized_user)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET /repos/:namespace/:project/commits/:sha' do
    let(:commit) { project.repository.commit }
    let(:commit_id) { commit.id }

    context 'authenticated' do
      it 'returns commit with github format' do
        stub_licensed_features(jira_dev_panel_integration: true)

        get v3_api("/repos/#{project.namespace.path}/#{project.path}/commits/#{commit_id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('entities/github/commit', dir: 'ee')
      end
    end

    context 'unauthenticated' do
      it 'returns 401' do
        get v3_api("/repos/#{project.namespace.path}/#{project.path}/commits/#{commit_id}", nil)

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'unauthorized' do
      it 'returns 404 when lower access level' do
        unauthorized_user = create(:user)
        project.add_guest(unauthorized_user)

        get v3_api("/repos/#{project.namespace.path}/#{project.path}/commits/#{commit_id}",
                   unauthorized_user)

        expect(response).to have_gitlab_http_status(404)
      end

      it 'returns 404 when not licensed' do
        stub_licensed_features(jira_dev_panel_integration: false)
        unauthorized_user = create(:user)
        project.add_reporter(unauthorized_user)

        get v3_api("/repos/#{project.namespace.path}/#{project.path}/commits/#{commit_id}",
                   unauthorized_user)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
