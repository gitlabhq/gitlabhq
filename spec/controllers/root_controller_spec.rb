# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RootController, feature_category: :shared do
  describe 'GET index' do
    context 'when user is not logged in' do
      it 'redirects to the sign-in page' do
        get :index

        expect(response).to redirect_to(new_user_session_path)
        expect(response).to have_gitlab_http_status(:found)
      end

      context 'when root redirect is enabled' do
        before do
          stub_application_setting(root_moved_permanently_redirection: true)
        end

        it 'redirects to the sign-in page with updated status and headers' do
          get :index

          expect(response).to have_gitlab_http_status(:moved_permanently)
          expect(response).to redirect_to(new_user_session_path)
          expect(response.headers["Cache-Control"]).to eq(described_class::CACHE_CONTROL_HEADER)
        end
      end

      context 'when a custom home page URL is defined' do
        before do
          stub_application_setting(home_page_url: 'https://gitlab.com')
        end

        it 'redirects the user to the custom home page URL' do
          get :index

          expect(response).to redirect_to('https://gitlab.com')
          expect(response).to have_gitlab_http_status(:found)
        end

        context 'when root redirect is enabled' do
          before do
            stub_application_setting(root_moved_permanently_redirection: true)
          end

          it 'redirects the user to the custom home page URL with updated status and headers' do
            get :index

            expect(response).to have_gitlab_http_status(:moved_permanently)
            expect(response).to redirect_to('https://gitlab.com')
            expect(response.headers["Cache-Control"]).to eq(described_class::CACHE_CONTROL_HEADER)
          end
        end
      end
    end

    context 'with a user' do
      let(:user) { create(:user) }

      before do
        sign_in(user)
        allow(subject).to receive(:current_user).and_return(user)
      end

      context 'who has customized their dashboard setting for starred projects' do
        before do
          user.dashboard = 'stars'
        end

        it 'redirects to their starred projects list' do
          get :index

          expect(response).to redirect_to starred_dashboard_projects_path
        end
      end

      context 'who has customized their dashboard setting for member projects' do
        before do
          user.dashboard = 'member_projects'
        end

        it 'redirects to their member projects list' do
          get :index

          expect(response).to redirect_to member_dashboard_projects_path
        end
      end

      context 'who has customized their dashboard setting for their own activities' do
        before do
          user.dashboard = 'your_activity'
        end

        it 'redirects to the activity list' do
          get :index

          expect(response).to redirect_to activity_dashboard_path
        end
      end

      context 'who has customized their dashboard setting for project activities' do
        before do
          user.dashboard = 'project_activity'
        end

        it 'redirects to the projects activity list' do
          get :index

          expect(response).to redirect_to activity_dashboard_path(filter: 'projects')
        end
      end

      context 'who has customized their dashboard setting for starred project activities' do
        before do
          user.dashboard = 'starred_project_activity'
        end

        it 'redirects to their starred projects activity list' do
          get :index

          expect(response).to redirect_to activity_dashboard_path(filter: 'starred')
        end
      end

      context 'who has customized their dashboard setting for followed user activities' do
        before do
          user.dashboard = 'followed_user_activity'
        end

        it 'redirects to the followed users activity list' do
          get :index

          expect(response).to redirect_to activity_dashboard_path(filter: 'followed')
        end
      end

      context 'who has customized their dashboard setting for groups' do
        before do
          user.dashboard = 'groups'
        end

        it 'redirects to their group list' do
          get :index

          expect(response).to redirect_to dashboard_groups_path
        end
      end

      context 'who has customized their dashboard setting for todos' do
        before do
          user.dashboard = 'todos'
        end

        it 'redirects to their todo list' do
          get :index

          expect(response).to redirect_to dashboard_todos_path
        end
      end

      context 'who has customized their dashboard setting for assigned issues' do
        before do
          user.dashboard = 'issues'
        end

        it 'redirects to their assigned issues' do
          get :index

          expect(response).to redirect_to issues_dashboard_path(assignee_username: user.username)
        end
      end

      context 'who has customized their dashboard setting for merge requests dashboard' do
        before do
          user.dashboard = 'merge_requests'
        end

        it 'redirects to merge requests dashboard' do
          get :index

          expect(response).to redirect_to merge_requests_dashboard_path
        end
      end

      context 'who has customized their dashboard setting for assigned merge requests' do
        before do
          user.dashboard = 'assigned_merge_requests'
        end

        it 'redirects to their assigned merge requests' do
          get :index

          expect(response).to redirect_to merge_requests_search_dashboard_path(assignee_username: user.username)
        end
      end

      context 'who has customized their dashboard setting for merge request reviews' do
        before do
          user.dashboard = 'review_merge_requests'
        end

        it 'redirects to their merge request reviews' do
          get :index

          expect(response).to redirect_to merge_requests_search_dashboard_path(reviewer_username: user.username)
        end
      end

      context 'who has customized their dashboard setting for personal homepage' do
        let_it_be(:duo_code_review_bot) { create(:user, :duo_code_review_bot) }

        before do
          user.dashboard = 'homepage'
        end

        context 'with `personal_homepage` feature flag disabled (default)' do
          before do
            stub_feature_flags(personal_homepage: false)
          end

          it 'renders the default dashboard' do
            get :index

            expect(response).to render_template 'dashboard/projects/index'
          end

          it 'does not track user_views_homepage event' do
            expect { get :index }.not_to trigger_internal_events('user_views_homepage')
          end

          it 'passes the correct data to the view' do
            get :index

            expect(assigns[:homepage_app_data]).to eq({
              review_requested_path: "/dashboard/merge_requests",
              activity_path: "/dashboard/activity",
              assigned_merge_requests_path: "/dashboard/merge_requests",
              assigned_work_items_path: "/dashboard/issues?assignee_username=#{user.username}",
              authored_work_items_path: "/dashboard/issues?author_username=#{user.username}",
              duo_code_review_bot_username: duo_code_review_bot.username,
              merge_requests_review_requested_title: "Review requested",
              merge_requests_your_merge_requests_title: "Your merge requests",
              last_push_event: nil
            })
          end
        end

        context 'with `personal_homepage` feature flag enabled' do
          before do
            stub_feature_flags(personal_homepage: true)
          end

          it 'renders the new homepage' do
            # With flipped mapping, homepage users actually get routed to projects
            # So we need to mock the effective_dashboard_for_routing to return homepage
            allow(user).to receive(:effective_dashboard_for_routing).and_return('homepage')

            get :index

            expect(response).to render_template 'root/index'
          end

          it 'tracks user_views_homepage event' do
            # With flipped mapping, homepage users actually get routed to projects
            # So we need to mock the effective_dashboard_for_routing to return homepage
            allow(user).to receive(:effective_dashboard_for_routing).and_return('homepage')

            expect { get :index }.to trigger_internal_events('user_views_homepage').with(user: user)
          end
        end
      end

      context 'who uses the default dashboard setting', :aggregate_failures do
        context 'with `personal_homepage` feature flag disabled (default)' do
          before do
            stub_feature_flags(personal_homepage: false)
          end

          it 'renders the default dashboard' do
            get :index

            expect(response).to render_template 'dashboard/projects/index'
          end

          it 'does not track user_views_homepage event' do
            expect { get :index }.not_to trigger_internal_events('user_views_homepage')
          end
        end

        context 'with `personal_homepage` feature flag enabled' do
          before do
            stub_feature_flags(personal_homepage: true)
          end

          it 'redirects to the default dashboard' do
            # With flipped mapping, default users (projects) get routed to homepage
            # So we need to mock the effective_dashboard_for_routing to return projects
            allow(user).to receive(:effective_dashboard_for_routing).and_return('projects')

            get :index

            expect(response).to redirect_to dashboard_projects_path
          end
        end
      end

      describe 'effective_dashboard_for_routing integration' do
        it 'calls effective_dashboard_for_routing instead of dashboard directly' do
          user.dashboard = 'projects'
          expect(user).to receive(:effective_dashboard_for_routing).and_call_original

          get :index
        end

        context 'with flipped dashboard mapping' do
          before do
            stub_feature_flags(personal_homepage: user)
            allow(user).to receive(:should_use_flipped_dashboard_mapping_for_rollout?).and_return(true)
          end

          it 'uses effective dashboard value for projects->homepage flip' do
            user.dashboard = 'projects'
            # Mock the effective method to return homepage (simulating the flip)
            allow(user).to receive(:effective_dashboard_for_routing).and_return('homepage')

            get :index

            expect(response).to render_template 'root/index'
          end

          it 'uses effective dashboard value for homepage->projects flip' do
            user.dashboard = 'homepage'
            # Mock the effective method to return projects (simulating the flip)
            allow(user).to receive(:effective_dashboard_for_routing).and_return('projects')

            get :index

            expect(response).to redirect_to dashboard_projects_path
          end
        end
      end
    end
  end
end
