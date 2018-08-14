require 'spec_helper'

describe RootController do
  describe 'GET index' do
    context 'when user is not logged in' do
      it 'redirects to the sign-in page' do
        get :index

        expect(response).to redirect_to(new_user_session_path)
      end

      context 'when a custom home page URL is defined' do
        before do
          stub_application_setting(home_page_url: 'https://gitlab.com')
        end

        it 'redirects the user to the custom home page URL' do
          get :index

          expect(response).to redirect_to('https://gitlab.com')
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

        it 'redirects to their specified dashboard' do
          get :index

          expect(response).to redirect_to starred_dashboard_projects_path
        end
      end

      context 'who has customized their dashboard setting for project activities' do
        before do
          user.dashboard = 'project_activity'
        end

        it 'redirects to the activity list' do
          get :index

          expect(response).to redirect_to activity_dashboard_path
        end
      end

      context 'who has customized their dashboard setting for starred project activities' do
        before do
          user.dashboard = 'starred_project_activity'
        end

        it 'redirects to the activity list' do
          get :index

          expect(response).to redirect_to activity_dashboard_path(filter: 'starred')
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

          expect(response).to redirect_to issues_dashboard_path(assignee_id: user.id)
        end
      end

      context 'who has customized their dashboard setting for assigned merge requests' do
        before do
          user.dashboard = 'merge_requests'
        end

        it 'redirects to their assigned merge requests' do
          get :index

          expect(response).to redirect_to merge_requests_dashboard_path(assignee_id: user.id)
        end
      end

      context 'who uses the default dashboard setting' do
        it 'renders the default dashboard' do
          get :index

          expect(response).to render_template 'dashboard/projects/index'
        end
      end
    end
  end
end
