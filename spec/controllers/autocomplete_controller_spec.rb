# frozen_string_literal: true

require 'spec_helper'

describe AutocompleteController do
  let(:project) { create(:project) }
  let(:user) { project.owner }

  context 'GET users' do
    let!(:user2) { create(:user) }
    let!(:non_member) { create(:user) }

    context 'project members' do
      before do
        sign_in(user)
      end

      describe 'GET #users with project ID' do
        before do
          get(:users, params: { project_id: project.id })
        end

        it 'returns the project members' do
          expect(json_response).to be_kind_of(Array)
          expect(json_response.size).to eq(1)
          expect(json_response.map { |u| u["username"] }).to include(user.username)
        end
      end

      describe 'GET #users with unknown project' do
        before do
          get(:users, params: { project_id: 'unknown' })
        end

        it { expect(response).to have_gitlab_http_status(404) }
      end
    end

    context 'group members' do
      let(:group) { create(:group) }

      before do
        group.add_owner(user)
        sign_in(user)
      end

      describe 'GET #users with group ID' do
        before do
          get(:users, params: { group_id: group.id })
        end

        it 'returns the group members' do
          expect(json_response).to be_kind_of(Array)
          expect(json_response.size).to eq(1)
          expect(json_response.first["username"]).to eq user.username
        end
      end

      describe 'GET #users with unknown group ID' do
        before do
          get(:users, params: { group_id: 'unknown' })
        end

        it { expect(response).to have_gitlab_http_status(404) }
      end
    end

    context 'non-member login for public project' do
      let(:project) { create(:project, :public) }

      before do
        sign_in(non_member)
      end

      describe 'GET #users with project ID' do
        before do
          get(:users, params: { project_id: project.id, current_user: true })
        end

        it 'returns the project members and non-members' do
          expect(json_response).to be_kind_of(Array)
          expect(json_response.size).to eq(2)
          expect(json_response.map { |u| u['username'] }).to include(user.username, non_member.username)
        end
      end
    end

    context 'all users' do
      before do
        sign_in(user)
        get(:users)
      end

      it { expect(json_response).to be_kind_of(Array) }
      it { expect(json_response.size).to eq User.count }
    end

    context 'user order' do
      it 'shows exact matches first' do
        reported_user = create(:user, username: 'reported_user', name: 'Doug')
        user = create(:user, username: 'user', name: 'User')
        user1 = create(:user, username: 'user1', name: 'Ian')

        sign_in(user)
        get(:users, params: { search: 'user' })

        response_usernames = json_response.map { |user| user['username']  }

        expect(response_usernames.take(3)).to match_array([user.username, reported_user.username, user1.username])
      end
    end

    context 'limited users per page' do
      before do
        create_list(:user, 25)

        sign_in(user)
        get(:users)
      end

      it { expect(json_response).to be_kind_of(Array) }
      it { expect(json_response.size).to eq(20) }
    end

    context 'unauthenticated user' do
      let(:public_project) { create(:project, :public) }

      describe 'GET #users with public project' do
        before do
          public_project.add_guest(user)
          get(:users, params: { project_id: public_project.id })
        end

        it { expect(json_response).to be_kind_of(Array) }
        it { expect(json_response.size).to eq 2 }
      end

      describe 'GET #users with project' do
        before do
          get(:users, params: { project_id: project.id })
        end

        it { expect(response).to have_gitlab_http_status(404) }
      end

      describe 'GET #users with unknown project' do
        before do
          get(:users, params: { project_id: 'unknown' })
        end

        it { expect(response).to have_gitlab_http_status(404) }
      end

      describe 'GET #users with inaccessible group' do
        before do
          project.add_guest(user)
          get(:users, params: { group_id: user.namespace.id })
        end

        it { expect(response).to have_gitlab_http_status(404) }
      end

      describe 'GET #users with no project' do
        before do
          get(:users)
        end

        it { expect(json_response).to be_kind_of(Array) }
        it { expect(json_response).to be_empty }
      end

      describe 'GET #users with todo filter' do
        it 'gives an array of users' do
          get :users, params: { todo_filter: true }

          expect(response.status).to eq 200
          expect(json_response).to be_kind_of(Array)
        end
      end
    end

    context 'author of issuable included' do
      context 'authenticated' do
        before do
          sign_in(user)
        end

        it 'includes the author' do
          get(:users, params: { author_id: non_member.id })

          expect(json_response.first["username"]).to eq non_member.username
        end

        it 'rejects non existent user ids' do
          get(:users, params: { author_id: 99999 })

          expect(json_response.collect { |u| u['id'] }).not_to include(99999)
        end
      end

      context 'without authenticating' do
        it 'returns empty result' do
          get(:users, params: { author_id: non_member.id })

          expect(json_response).to be_empty
        end
      end
    end

    context 'skip_users parameter included' do
      before do
        sign_in(user)
      end

      it 'skips the user IDs passed' do
        get(:users, params: { skip_users: [user, user2].map(&:id) })

        response_user_ids = json_response.map { |user| user['id'] }

        expect(response_user_ids).to contain_exactly(non_member.id)
      end
    end

    context 'merge_request_iid parameter included' do
      before do
        sign_in(user)
      end

      it 'includes can_merge option to users' do
        merge_request = create(:merge_request, source_project: project)

        get(:users, params: { merge_request_iid: merge_request.iid, project_id: project.id })

        expect(json_response.first).to have_key('can_merge')
      end
    end
  end

  context 'GET projects' do
    let(:authorized_project) { create(:project) }
    let(:authorized_search_project) { create(:project, name: 'rugged') }

    before do
      sign_in(user)
      project.add_maintainer(user)
    end

    context 'authorized projects' do
      before do
        authorized_project.add_maintainer(user)
      end

      describe 'GET #projects with project ID' do
        before do
          get(:projects, params: { project_id: project.id })
        end

        it 'returns projects' do
          expect(json_response).to be_kind_of(Array)
          expect(json_response.size).to eq(1)

          expect(json_response.first['id']).to eq authorized_project.id
          expect(json_response.first['name_with_namespace']).to eq authorized_project.full_name
        end
      end
    end

    context 'authorized projects and search' do
      before do
        authorized_project.add_maintainer(user)
        authorized_search_project.add_maintainer(user)
      end

      describe 'GET #projects with project ID and search' do
        before do
          get(:projects, params: { project_id: project.id, search: 'rugged' })
        end

        it 'returns projects' do
          expect(json_response).to be_kind_of(Array)
          expect(json_response.size).to eq(1)

          expect(json_response.first['id']).to eq authorized_search_project.id
          expect(json_response.first['name_with_namespace']).to eq authorized_search_project.full_name
        end
      end
    end

    context 'authorized projects apply limit' do
      before do
        allow(Kaminari.config).to receive(:default_per_page).and_return(2)

        create_list(:project, 2) do |project|
          project.add_maintainer(user)
        end
      end

      describe 'GET #projects with project ID' do
        before do
          get(:projects, params: { project_id: project.id })
        end

        it 'returns projects' do
          expect(json_response).to be_kind_of(Array)
          expect(json_response.size).to eq(Kaminari.config.default_per_page)
        end
      end
    end

    context 'authorized projects without admin_issue ability' do
      before do
        authorized_project.add_guest(user)

        expect(user.can?(:admin_issue, authorized_project)).to eq(false)
      end

      describe 'GET #projects with project ID' do
        before do
          get(:projects, params: { project_id: project.id })
        end

        it 'returns no projects' do
          expect(json_response).to be_kind_of(Array)
          expect(json_response.size).to eq(0)
        end
      end
    end
  end

  context 'GET award_emojis' do
    let(:user2) { create(:user) }
    let!(:award_emoji1) { create_list(:award_emoji, 2, user: user, name: 'thumbsup') }
    let!(:award_emoji2) { create_list(:award_emoji, 1, user: user, name: 'thumbsdown') }
    let!(:award_emoji3) { create_list(:award_emoji, 3, user: user, name: 'star') }
    let!(:award_emoji4) { create_list(:award_emoji, 1, user: user, name: 'tea') }

    context 'unauthorized user' do
      it 'returns empty json' do
        get :award_emojis

        expect(json_response).to be_empty
      end
    end

    context 'sign in as user without award emoji' do
      it 'returns empty json' do
        sign_in(user2)
        get :award_emojis

        expect(json_response).to be_empty
      end
    end

    context 'sign in as user with award emoji' do
      it 'returns json sorted by name count' do
        sign_in(user)
        get :award_emojis

        expect(json_response.count).to eq 4
        expect(json_response[0]).to match('name' => 'star')
        expect(json_response[1]).to match('name' => 'thumbsup')
        expect(json_response[2]).to match('name' => 'tea')
        expect(json_response[3]).to match('name' => 'thumbsdown')
      end
    end
  end

  context 'Get merge_request_target_branches' do
    let!(:merge_request) { create(:merge_request, source_project: project, target_branch: 'feature') }

    context 'anonymous user' do
      it 'returns empty json' do
        get :merge_request_target_branches, params: { project_id: project.id }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_empty
      end
    end

    context 'user without any accessible merge requests' do
      it 'returns empty json' do
        sign_in(create(:user))

        get :merge_request_target_branches, params: { project_id: project.id }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_empty
      end
    end

    context 'user with an accessible merge request but no scope' do
      where(
        params: [
          {},
          { group_id: ' ' },
          { project_id: ' ' },
          { group_id: ' ', project_id: ' ' }
        ]
      )

      with_them do
        it 'returns an error' do
          sign_in(user)

          get :merge_request_target_branches, params: params

          expect(response).to have_gitlab_http_status(400)
          expect(json_response).to eq({ 'error' => 'At least one of group_id or project_id must be specified' })
        end
      end
    end

    context 'user with an accessible merge request by project' do
      it 'returns json' do
        sign_in(user)

        get :merge_request_target_branches, params: { project_id: project.id }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to contain_exactly({ 'title' => 'feature' })
      end
    end

    context 'user with an accessible merge request by group' do
      let(:group) { create(:group) }
      let(:project) { create(:project, namespace: group) }
      let(:user) { create(:user) }

      it 'returns json' do
        group.add_owner(user)

        sign_in(user)

        get :merge_request_target_branches, params: { group_id: group.id }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to contain_exactly({ 'title' => 'feature' })
      end
    end
  end
end
