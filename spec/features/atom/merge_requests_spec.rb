# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Requests Feed', feature_category: :devops_reports do
  describe 'GET /merge_requests' do
    let_it_be_with_reload(:user) { create(:user, email: 'private1@example.com') }
    let_it_be(:assignee) { create(:user, email: 'private2@example.com') }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project, assignees: [assignee]) }
    let_it_be(:issuable) { merge_request } # "alias" for shared examples

    before_all do
      project.add_developer(user)
      group.add_developer(user)
    end

    RSpec.shared_examples 'an authenticated merge request atom feed' do
      it 'renders atom feed with additional merge request information' do
        expect(body).to have_selector('title', text: "#{project.name} merge requests")
      end
    end

    context 'when authenticated' do
      before do
        sign_in user
        visit project_merge_requests_path(project, :atom)
      end

      it_behaves_like 'an authenticated issuable atom feed'
      it_behaves_like 'an authenticated merge request atom feed'

      context 'but the use can not see the project' do
        let_it_be(:other_project) { create(:project) }

        it 'renders 404 page' do
          visit project_issues_path(other_project, :atom)

          expect(page).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when authenticated via personal access token' do
      before do
        personal_access_token = create(:personal_access_token, user: user)

        visit project_merge_requests_path(
          project,
          :atom,
          private_token: personal_access_token.token
        )
      end

      it_behaves_like 'an authenticated issuable atom feed'
      it_behaves_like 'an authenticated merge request atom feed'
    end

    context 'when authenticated via feed token' do
      before do
        visit project_merge_requests_path(
          project,
          :atom,
          feed_token: user.feed_token
        )
      end

      it_behaves_like 'an authenticated issuable atom feed'
      it_behaves_like 'an authenticated merge request atom feed'
    end

    context 'when not authenticated' do
      before do
        visit project_merge_requests_path(project, :atom)
      end

      context 'and the project is private' do
        it 'redirects to login page' do
          expect(page).to have_current_path(new_user_session_path)
        end
      end

      context 'and the project is public' do
        let_it_be(:project) { create(:project, :public, :repository) }
        let_it_be(:merge_request) { create(:merge_request, source_project: project, assignees: [assignee]) }
        let_it_be(:issuable) { merge_request } # "alias" for shared examples

        it_behaves_like 'an authenticated issuable atom feed'
        it_behaves_like 'an authenticated merge request atom feed'
      end
    end
  end

  describe 'GET /groups/:group/-/merge_requests' do
    let_it_be_with_reload(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :repository, group: group) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }

    before_all do
      group.add_developer(user)
    end

    context 'when authenticated' do
      before do
        sign_in user
        visit merge_requests_group_path(group, :atom)
      end

      it 'renders atom feed' do
        expect(page).to have_gitlab_http_status(:ok)
      end

      it 'renders atom feed with group merge requests title' do
        expect(body).to have_selector('title', text: "#{group.name} merge requests", visible: :all)
      end
    end

    context 'when authenticated via feed token' do
      before do
        visit merge_requests_group_path(group, :atom, feed_token: user.feed_token)
      end

      it 'renders atom feed' do
        expect(page).to have_gitlab_http_status(:ok)
      end

      it 'renders atom feed with group merge requests title' do
        expect(body).to have_selector('title', text: "#{group.name} merge requests", visible: :all)
      end
    end

    context 'when not authenticated' do
      context 'and the group is private' do
        before do
          visit merge_requests_group_path(group, :atom)
        end

        it 'renders atom feed with no merge requests' do
          expect(page).to have_gitlab_http_status(:ok)
          expect(body).not_to have_selector('entry')
        end
      end

      context 'and the group is public' do
        let_it_be(:group) { create(:group, :public) }
        let_it_be(:project) { create(:project, :public, :repository, group: group) }
        let_it_be(:merge_request) { create(:merge_request, source_project: project) }

        before do
          visit merge_requests_group_path(group, :atom)
        end

        it 'renders atom feed' do
          expect(page).to have_gitlab_http_status(:ok)
        end

        it 'renders atom feed with group merge requests title' do
          expect(body).to have_selector('title', text: "#{group.name} merge requests", visible: :all)
        end
      end
    end
  end
end
