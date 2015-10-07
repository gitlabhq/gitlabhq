require 'spec_helper'

describe RootController do
  describe 'GET index' do
    context 'with a user' do
      let(:user) { create(:user) }

      before do
        sign_in(user)
        allow(subject).to receive(:current_user).and_return(user)
      end

      context 'who has customized their dashboard setting for starred projects' do
        before do
          user.update_attribute(:dashboard, 'stars')
        end

        it 'redirects to their specified dashboard' do
          get :index
          expect(response).to redirect_to starred_dashboard_projects_path
        end
      end

      context 'who has customized their dashboard setting for project activities' do
        before do
          user.update_attribute(:dashboard, 'project_activity')
        end

        it 'redirects to the activity list' do
          get :index
          expect(response).to redirect_to activity_dashboard_path
        end
      end

      context 'who has customized their dashboard setting for starred project activities' do
        before do
          user.update_attribute(:dashboard, 'starred_project_activity')
        end

        it 'redirects to the activity list' do
          get :index
          expect(response).to redirect_to activity_dashboard_path(filter: 'starred')
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
