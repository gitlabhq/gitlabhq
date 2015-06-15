require 'spec_helper'

describe RootController do
  describe 'GET show' do
    context 'with a user' do
      let(:user) { create(:user) }

      before do
        sign_in(user)
        allow(subject).to receive(:current_user).and_return(user)
      end

      context 'who has customized their dashboard setting' do
        before do
          user.update_attribute(:dashboard, 'stars')
        end

        it 'redirects to their specified dashboard' do
          get :show
          expect(response).to redirect_to starred_dashboard_projects_path
        end
      end

      context 'who uses the default dashboard setting' do
        it 'renders the default dashboard' do
          get :show
          expect(response).to render_template 'dashboard/show'
        end
      end
    end
  end
end
