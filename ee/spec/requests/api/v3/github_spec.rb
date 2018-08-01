require 'spec_helper'

describe API::V3::Github do
  let(:user) { create(:user) }
  let!(:project) { create(:project, :repository, creator: user) }

  before do
    allow(Gitlab::Jira::Middleware).to receive(:jira_dvcs_connector?) { true }
    project.add_maintainer(user)
  end

  describe 'GET /orgs/:namespace/repos' do
    it 'returns an empty array' do
      group = create(:group)

      get v3_api("/orgs/#{group.path}/repos", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to eq([])
    end

    it 'returns 200 when namespace path include a dot' do
      group = create(:group, path: 'foo.bar')

      get v3_api("/orgs/#{group.path}/repos", user)

      expect(response).to have_gitlab_http_status(200)
    end
  end

  describe 'GET /user/repos' do
    it 'returns an empty array' do
      get v3_api('/user/repos', user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to eq([])
    end
  end

  describe 'GET /repos/-/jira/events' do
    it 'returns an empty array' do
      get v3_api('/repos/-/jira/events', user)

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
    let(:group) { create(:group, name: 'foo') }

    def expect_project_under_namespace(projects, namespace, user)
      get v3_api("/users/#{namespace.path}/repos", user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(response).to match_response_schema('entities/github/repositories', dir: 'ee')

      projects.each do |project|
        hash = json_response.find do |hash|
          hash['name'] == ::Gitlab::Jira::Dvcs.encode_project_name(project)
        end

        raise "Project #{project.full_path} not present in response" if hash.nil?

        expect(hash['owner']['login']).to eq(namespace.name)
      end
      expect(json_response.size).to eq(projects.size)
    end

    context 'group namespace' do
      let(:project) { create(:project, group: group) }

      before do
        stub_licensed_features(jira_dev_panel_integration: true)
        group.add_maintainer(user)
      end

      it 'returns an array of projects belonging to group with github format' do
        expect_project_under_namespace([project], group, user)
      end
    end

    context 'nested group namespace', :nested_groups do
      let(:group) { create(:group, :nested) }
      let!(:parent_group_project) { create(:project, group: group.parent, name: 'parent_group_project') }
      let!(:child_group_project) { create(:project, group: group, name: 'child_group_project') }

      before do
        stub_licensed_features(jira_dev_panel_integration: true)
        group.parent.add_maintainer(user)
      end

      it 'returns an array of projects belonging to group with github format' do
        expect_project_under_namespace([parent_group_project, child_group_project], group.parent, user)
      end
    end

    context 'user namespace' do
      let(:project) { create(:project, namespace: user.namespace) }

      before do
        stub_licensed_features(jira_dev_panel_integration: true)
      end

      it 'returns an array of projects belonging to user namespace with github format' do
        expect_project_under_namespace([project], user.namespace, user)
      end
    end

    context 'namespace path includes a dot' do
      let(:project) { create(:project, group: group) }
      let(:group) { create(:group, name: 'foo.bar') }

      before do
        stub_licensed_features(jira_dev_panel_integration: true)
        group.add_maintainer(user)
      end

      it 'returns an array of projects belonging to group with github format' do
        expect_project_under_namespace([project], group, user)
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
      licensed_project = create(:project, :empty_repo, group: group)
      licensed_project.add_reporter(user)
      licensed_project.namespace.update!(plan_id: silver_plan.id)

      stub_licensed_features(jira_dev_panel_integration: true)
      stub_application_setting_on_object(project, should_check_namespace_plan: true)
      stub_application_setting_on_object(licensed_project, should_check_namespace_plan: true)

      expect_project_under_namespace([licensed_project], group, user)
    end

    context 'namespace does not exist' do
      it 'responds with not found status' do
        stub_licensed_features(jira_dev_panel_integration: true)

        get v3_api("/users/noo/repos", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET /repos/:namespace/:project/branches' do
    context 'authenticated' do
      before do
        stub_licensed_features(jira_dev_panel_integration: true)
      end

      it 'returns an array of project branches with github format' do
        get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)

        expect(response).to match_response_schema('entities/github/branches', dir: 'ee')
      end

      it 'returns 200 when project path include a dot' do
        project.update!(path: 'foo.bar')

        get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", user)

        expect(response).to have_gitlab_http_status(200)
      end

      it 'returns 200 when namespace path include a dot' do
        group = create(:group, path: 'foo.bar')
        project = create(:project, :repository, group: group)
        project.add_reporter(user)

        get v3_api("/repos/#{group.path}/#{project.path}/branches", user)

        expect(response).to have_gitlab_http_status(200)
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
      before do
        stub_licensed_features(jira_dev_panel_integration: true)
      end

      it 'returns commit with github format' do
        get v3_api("/repos/#{project.namespace.path}/#{project.path}/commits/#{commit_id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('entities/github/commit', dir: 'ee')
      end

      it 'returns 200 when project path include a dot' do
        project.update!(path: 'foo.bar')

        get v3_api("/repos/#{project.namespace.path}/#{project.path}/commits/#{commit_id}", user)

        expect(response).to have_gitlab_http_status(200)
      end

      it 'returns 200 when namespace path include a dot' do
        group = create(:group, path: 'foo.bar')
        project = create(:project, :repository, group: group)
        project.add_reporter(user)

        get v3_api("/repos/#{group.path}/#{project.path}/commits/#{commit_id}", user)

        expect(response).to have_gitlab_http_status(200)
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

  def v3_api(path, user = nil, personal_access_token: nil, oauth_access_token: nil)
    api(
      path,
      user,
      version: 'v3',
      personal_access_token: personal_access_token,
      oauth_access_token: oauth_access_token
    )
  end
end
