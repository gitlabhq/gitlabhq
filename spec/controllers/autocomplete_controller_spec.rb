require 'spec_helper'

describe AutocompleteController do
  let!(:project) { create(:empty_project) }
  let!(:user) { create(:user) }

  context 'GET users' do
    let!(:user2) { create(:user) }
    let!(:non_member) { create(:user) }

    context 'project members' do
      before do
        sign_in(user)
        project.add_master(user)
        project.add_developer(user2)
      end

      describe 'GET #users with project ID' do
        before do
          get(:users, project_id: project.id)
        end

        let(:body) { JSON.parse(response.body) }

        it { expect(body).to be_kind_of(Array) }
        it { expect(body.size).to eq 3 }
        it { expect(body.map { |u| u["username"] }).to match_array([project.owner.username, user.username, user2.username]) }
      end

      describe 'GET #users with unknown project' do
        before do
          get(:users, project_id: 'unknown')
        end

        it { expect(response).to have_http_status(404) }
      end

      describe "GET #users that can push to protected branches" do
        before do
          get(:users, project_id: project.id, push_code_to_protected_branches: 'true')
        end

        let(:body) { JSON.parse(response.body) }

        it { expect(body).to be_kind_of(Array) }
        it { expect(body.size).to eq 2 }
        it { expect(body.map { |u| u["username"] }).to match_array([project.owner.username, user.username]) }
      end

      describe "GET #users that can push code" do
        let(:reporter_user) { create(:user) }

        before do
          project.team << [reporter_user, :reporter]
          get(:users, project_id: project.id, push_code: 'true')
        end

        let(:body) { JSON.parse(response.body) }

        it { expect(body).to be_kind_of(Array) }
        it { expect(body.size).to eq 3 }
        it { expect(body.map { |user| user["username"] }).to match_array([project.owner.username, user.username, user2.username]) }
      end

      describe "GET #users that can push to protected branches, including the current user" do
        before do
          get(:users, project_id: project.id, push_code_to_protected_branches: true, current_user: true)
        end

        let(:body) { JSON.parse(response.body) }

        it { expect(body).to be_kind_of(Array) }
        it { expect(body.size).to eq 2 }
        it { expect(body.map { |u| u["username"] }).to match_array([project.owner.username, user.username]) }
      end
    end

    context 'group members' do
      let(:group) { create(:group) }

      before do
        sign_in(user)
        group.add_owner(user)
      end

      let(:body) { JSON.parse(response.body) }

      describe 'GET #users with group ID' do
        before do
          get(:users, group_id: group.id)
        end

        it { expect(body).to be_kind_of(Array) }
        it { expect(body.size).to eq 1 }
        it { expect(body.first["username"]).to eq user.username }
      end

      describe 'GET #users with unknown group ID' do
        before do
          get(:users, group_id: 'unknown')
        end

        it { expect(response).to have_http_status(404) }
      end
    end

    context 'non-member login for public project' do
      let!(:project) { create(:project, :public) }

      before do
        sign_in(non_member)
        project.add_master(user)
      end

      let(:body) { JSON.parse(response.body) }

      describe 'GET #users with project ID' do
        before do
          get(:users, project_id: project.id, current_user: true)
        end

        it { expect(body).to be_kind_of(Array) }
        it { expect(body.size).to eq 3 }
        it { expect(body.map { |u| u['username'] }).to include(user.username, non_member.username) }
      end
    end

    context 'all users' do
      before do
        sign_in(user)
        get(:users)
      end

      let(:body) { JSON.parse(response.body) }

      it { expect(body).to be_kind_of(Array) }
      it { expect(body.size).to eq User.count }
    end

    context 'user order' do
      it 'shows exact matches first' do
        reported_user = create(:user, username: 'reported_user', name: 'Doug')
        user = create(:user, username: 'user', name: 'User')
        user1 = create(:user, username: 'user1', name: 'Ian')

        sign_in(user)
        get(:users, search: 'user')

        response_usernames = JSON.parse(response.body).map { |user| user['username']  }

        expect(response_usernames.take(3)).to match_array([user.username, reported_user.username, user1.username])
      end
    end

    context 'limited users per page' do
      let(:per_page) { 2 }

      before do
        sign_in(user)
        get(:users, per_page: per_page)
      end

      let(:body) { JSON.parse(response.body) }

      it { expect(body).to be_kind_of(Array) }
      it { expect(body.size).to eq per_page }
    end

    context 'unauthenticated user' do
      let(:public_project) { create(:project, :public) }
      let(:body) { JSON.parse(response.body) }

      describe 'GET #users with public project' do
        before do
          public_project.add_guest(user)
          get(:users, project_id: public_project.id)
        end

        it { expect(body).to be_kind_of(Array) }
        it { expect(body.size).to eq 2 }
      end

      describe 'GET #users with project' do
        before do
          get(:users, project_id: project.id)
        end

        it { expect(response).to have_http_status(404) }
      end

      describe 'GET #users with unknown project' do
        before do
          get(:users, project_id: 'unknown')
        end

        it { expect(response).to have_http_status(404) }
      end

      describe 'GET #users with inaccessible group' do
        before do
          project.add_guest(user)
          get(:users, group_id: user.namespace.id)
        end

        it { expect(response).to have_http_status(404) }
      end

      describe 'GET #users with no project' do
        before do
          get(:users)
        end

        it { expect(body).to be_kind_of(Array) }
        it { expect(body.size).to eq 0 }
      end

      describe 'GET #users with todo filter' do
        it 'gives an array of users' do
          get :users, todo_filter: true

          expect(response.status).to eq 200
          expect(body).to be_kind_of(Array)
        end
      end
    end

    context 'author of issuable included' do
      let(:body) { JSON.parse(response.body) }

      context 'authenticated' do
        before do
          sign_in(user)
        end

        it 'includes the author' do
          get(:users, author_id: non_member.id)

          expect(body.first["username"]).to eq non_member.username
        end

        it 'rejects non existent user ids' do
          get(:users, author_id: 99999)

          expect(body.collect { |u| u['id'] }).not_to include(99999)
        end
      end

      context 'without authenticating' do
        it 'returns empty result' do
          get(:users, author_id: non_member.id)

          expect(body).to be_empty
        end
      end
    end

    context 'skip_users parameter included' do
      before do
        sign_in(user)
      end

      it 'skips the user IDs passed' do
        get(:users, skip_users: [user, user2].map(&:id))

        other_user_ids    = [non_member, project.owner, project.creator].map(&:id)
        response_user_ids = JSON.parse(response.body).map { |user| user['id'] }

        expect(response_user_ids).to contain_exactly(*other_user_ids)
      end
    end
  end

  context 'GET projects' do
    let(:authorized_project) { create(:project) }
    let(:authorized_search_project) { create(:project, name: 'rugged') }

    before do
      sign_in(user)
      project.add_master(user)
    end

    context 'authorized projects' do
      before do
        authorized_project.add_master(user)
      end

      describe 'GET #projects with project ID' do
        before do
          get(:projects, project_id: project.id)
        end

        let(:body) { JSON.parse(response.body) }

        it do
          expect(body).to be_kind_of(Array)
          expect(body.size).to eq 2

          expect(body.first['id']).to eq 0
          expect(body.first['name_with_namespace']).to eq 'No project'

          expect(body.last['id']).to eq authorized_project.id
          expect(body.last['name_with_namespace']).to eq authorized_project.name_with_namespace
        end
      end
    end

    context 'authorized projects and search' do
      before do
        authorized_project.add_master(user)
        authorized_search_project.add_master(user)
      end

      describe 'GET #projects with project ID and search' do
        before do
          get(:projects, project_id: project.id, search: 'rugged')
        end

        let(:body) { JSON.parse(response.body) }

        it do
          expect(body).to be_kind_of(Array)
          expect(body.size).to eq 2

          expect(body.last['id']).to eq authorized_search_project.id
          expect(body.last['name_with_namespace']).to eq authorized_search_project.name_with_namespace
        end
      end
    end

    context 'authorized projects apply limit' do
      before do
        authorized_project2 = create(:project)
        authorized_project3 = create(:project)

        authorized_project.add_master(user)
        authorized_project2.add_master(user)
        authorized_project3.add_master(user)

        stub_const 'MoveToProjectFinder::PAGE_SIZE', 2
      end

      describe 'GET #projects with project ID' do
        before do
          get(:projects, project_id: project.id)
        end

        let(:body) { JSON.parse(response.body) }

        it do
          expect(body).to be_kind_of(Array)
          expect(body.size).to eq 3 # Of a total of 4
        end
      end
    end

    context 'authorized projects with offset' do
      before do
        authorized_project2 = create(:project)
        authorized_project3 = create(:project)

        authorized_project.add_master(user)
        authorized_project2.add_master(user)
        authorized_project3.add_master(user)
      end

      describe 'GET #projects with project ID and offset_id' do
        before do
          get(:projects, project_id: project.id, offset_id: authorized_project.id)
        end

        let(:body) { JSON.parse(response.body) }

        it do
          expect(body.detect { |item| item['id'] == 0 }).to be_nil # 'No project' is not there
          expect(body.detect { |item| item['id'] == authorized_project.id }).to be_nil # Offset project is not there either
        end
      end
    end

    context 'authorized projects without admin_issue ability' do
      before(:each) do
        authorized_project.add_guest(user)

        expect(user.can?(:admin_issue, authorized_project)).to eq(false)
      end

      describe 'GET #projects with project ID' do
        before do
          get(:projects, project_id: project.id)
        end

        let(:body) { JSON.parse(response.body) }

        it do
          expect(body).to be_kind_of(Array)
          expect(body.size).to eq 1 # 'No project'

          expect(body.first['id']).to eq 0
        end
      end
    end
  end

  context "groups" do
    let(:matching_group) { create(:group) }
    let(:non_matching_group) { create(:group) }

    context "while fetching all groups belonging to a project" do
      before do
        project.team << [user, :developer]
        project.invited_groups << matching_group
        sign_in(user)
        get(:project_groups, project_id: project.id)
      end

      let(:body) { JSON.parse(response.body) }

      it { expect(body).to be_kind_of(Array) }
      it { expect(body.size).to eq 1 }
      it { expect(body.first.values_at('id', 'name')).to eq [matching_group.id, matching_group.name] }
    end

    context "while fetching all groups belonging to a project the current user cannot access" do
      before do
        project.invited_groups << matching_group
        sign_in(user)
        get(:project_groups, project_id: project.id)
      end

      it { expect(response).to be_not_found }
    end

    context "while fetching all groups belonging to an invalid project ID" do
      before do
        project.invited_groups << matching_group
        sign_in(user)
        get(:project_groups, project_id: 'invalid')
      end

      it { expect(response).to be_not_found }
    end
  end
end
