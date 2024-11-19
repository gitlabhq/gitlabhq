# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AutocompleteController do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.first_owner }

  context 'GET users', feature_category: :user_management do
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

        context "with push_code param" do
          let(:reporter) { create(:user) }

          before do
            project.add_reporter(reporter)

            get(:users, params: { project_id: project.id, push_code: 'true' })
          end

          it 'returns users that can push code', :aggregate_failures do
            expect(json_response).to be_kind_of(Array)
            expect(json_response.size).to eq(1)
            expect(json_response.map { |user| user["username"] }).to match_array([user.username])
          end
        end
      end

      describe 'GET #users with unknown project' do
        before do
          get(:users, params: { project_id: 'unknown' })
        end

        it { expect(response).to have_gitlab_http_status(:not_found) }
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

        it { expect(response).to have_gitlab_http_status(:not_found) }
      end
    end

    context 'non-member login for public project' do
      let(:project) { create(:project, :public) }
      let(:user) { project.first_owner }

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
      it 'shows exact matches first', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/375028' do
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

        it { expect(response).to have_gitlab_http_status(:not_found) }
      end

      describe 'GET #users with unknown project' do
        before do
          get(:users, params: { project_id: 'unknown' })
        end

        it { expect(response).to have_gitlab_http_status(:not_found) }
      end

      describe 'GET #users with inaccessible group' do
        before do
          project.add_guest(user)
          get(:users, params: { group_id: user.namespace.id })
        end

        it { expect(response).to have_gitlab_http_status(:not_found) }
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

          expect(response).to have_gitlab_http_status(:ok)
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
          get(:users, params: { author_id: non_existing_record_id })

          expect(json_response.collect { |u| u['id'] }).not_to include(non_existing_record_id)
        end
      end

      context 'without authenticating' do
        it 'returns empty result' do
          get(:users, params: { author_id: non_member.id })

          expect(json_response).to be_empty
        end
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

    it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit do
      let(:current_user) { user }

      def request
        get(:users, params: { search: 'foo@bar.com' })
      end

      before do
        sign_in(current_user)
      end
    end
  end

  context 'GET projects', feature_category: :groups_and_projects do
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

  context 'GET award_emojis', feature_category: :team_planning do
    let(:user2) { create(:user) }
    let!(:award_emoji1) { create_list(:award_emoji, 2, user: user, name: AwardEmoji::THUMBS_UP) }
    let!(:award_emoji2) { create_list(:award_emoji, 1, user: user, name: AwardEmoji::THUMBS_DOWN) }
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
        expect(json_response[1]).to match('name' => AwardEmoji::THUMBS_UP)
        expect(json_response[2]).to match('name' => 'tea')
        expect(json_response[3]).to match('name' => AwardEmoji::THUMBS_DOWN)
      end
    end
  end

  context 'GET deploy_keys_with_owners', feature_category: :continuous_delivery do
    let_it_be(:public_project) { create(:project, :public) }
    let_it_be(:user) { create(:user) }
    let_it_be(:deploy_key) { create(:deploy_key, user: user) }
    let_it_be(:deploy_keys_project) do
      create(:deploy_keys_project, :write_access, project: public_project, deploy_key: deploy_key)
    end

    context 'unauthorized user' do
      it 'returns a not found response' do
        get(:deploy_keys_with_owners, params: { project_id: public_project.id })

        expect(response).to have_gitlab_http_status(:redirect)
      end
    end

    context 'when the user is logged in' do
      before do
        sign_in(user)
      end

      context 'with a non-existing project' do
        it 'returns a not found response' do
          get(:deploy_keys_with_owners, params: { project_id: 9999 })

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'with an existing project' do
        context 'when user cannot admin project' do
          it 'returns a forbidden response' do
            get(:deploy_keys_with_owners, params: { project_id: public_project.id })

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when user can admin project' do
          before do
            public_project.add_maintainer(user)
          end

          context 'and user can read owner of key' do
            it 'renders the deploy keys in a json payload, with owner' do
              get(:deploy_keys_with_owners, params: { project_id: public_project.id })

              expect(json_response.count).to eq(1)
              expect(json_response.first['title']).to eq(deploy_key.title)
              expect(json_response.first['owner']['id']).to eq(deploy_key.user.id)
              expect(json_response.first['deploy_keys_projects']).to be_nil
            end
          end

          context 'and user cannot read owner of key' do
            before do
              allow(Ability).to receive(:allowed?).and_call_original
              allow(Ability).to receive(:allowed?).with(user, :read_user, deploy_key.user).and_return(false)
            end

            it 'returns a payload without owner' do
              get(:deploy_keys_with_owners, params: { project_id: public_project.id })

              expect(json_response.count).to eq(1)
              expect(json_response.first['title']).to eq(deploy_key.title)
              expect(json_response.first['owner']).to be_nil
              expect(json_response.first['deploy_keys_projects']).to be_nil
            end
          end
        end
      end
    end
  end

  context 'GET branches', feature_category: :code_review_workflow do
    let_it_be(:merge_request) do
      create(:merge_request, source_project: project,
        source_branch: 'test_source_branch', target_branch: 'test_target_branch')
    end

    shared_examples 'Get merge_request_{}_branches' do |path, expected_result|
      context 'anonymous user' do
        it 'returns empty json' do
          get path, params: { project_id: project.id }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_empty
        end
      end

      context 'user without any accessible merge requests' do
        it 'returns empty json' do
          sign_in(create(:user))

          get path, params: { project_id: project.id }

          expect(response).to have_gitlab_http_status(:ok)
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

            get path, params: params

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response).to eq({ 'error' => 'At least one of group_id or project_id must be specified' })
          end
        end
      end

      context 'user with an accessible merge request by project' do
        it 'returns json' do
          sign_in(user)

          get path, params: { project_id: project.id }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to contain_exactly(expected_result)
        end
      end

      context 'user with an accessible merge request by group' do
        let(:group) { create(:group) }
        let(:user) { create(:user) }

        it 'returns json' do
          project.update!(namespace: group)
          group.add_owner(user)

          sign_in(user)

          get path, params: { group_id: group.id }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to contain_exactly(expected_result)
        end
      end
    end

    it_behaves_like 'Get merge_request_{}_branches', :merge_request_target_branches, { 'title' => 'test_target_branch' }
    it_behaves_like 'Get merge_request_{}_branches', :merge_request_source_branches, { 'title' => 'test_source_branch' }
  end
end
