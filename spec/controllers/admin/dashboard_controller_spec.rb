require 'spec_helper'

describe Admin::DashboardController do
  describe '#index' do
    it "allows an admin user to access the page" do
      sign_in(create(:user, :admin))
      get :index

      expect(response).to have_http_status(200)
    end

    it "does not allow an auditor user to access the page" do
      sign_in(create(:user, :auditor))
      get :index

      expect(response).to have_http_status(404)
    end

    it "does not allow a regular user to access the page" do
      sign_in(create(:user))
      get :index

      expect(response).to have_http_status(404)
    end

    context 'with pending_delete projects' do
      render_views

      it 'does not retrieve projects that are pending deletion' do
        sign_in(create(:admin))

        project = create(:project)
        pending_delete_project = create(:project, pending_delete: true)

        get :index

        expect(response.body).to match(project.name)
        expect(response.body).not_to match(pending_delete_project.name)
      end
    end
  end
end
