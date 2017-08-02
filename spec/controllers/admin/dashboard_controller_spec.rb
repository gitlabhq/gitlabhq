require 'spec_helper'

describe Admin::DashboardController do
  describe '#index' do
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
