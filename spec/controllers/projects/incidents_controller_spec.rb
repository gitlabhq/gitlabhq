# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IncidentsController do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:guest) { create(:user) }

  before_all do
    project.add_guest(guest)
    project.add_developer(developer)
  end

  describe 'GET #index' do
    def make_request
      get :index, params: { namespace_id: project.namespace, project_id: project }
    end

    it 'shows the page for users with guest role' do
      sign_in(guest)
      make_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:index)
    end

    it 'shows the page for users with developer role' do
      sign_in(developer)
      make_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:index)
    end

    context 'when user is unauthorized' do
      it 'redirects to the login page' do
        make_request

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
