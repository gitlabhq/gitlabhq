require 'spec_helper'

describe Projects::EnvironmentsController do
  let(:environment) { create(:environment) }
  let(:project)     { environment.project }
  let(:user)        { create(:user) }

  before do
    project.team << [user, :master]

    sign_in(user)
  end

  render_views

  describe 'GET show' do
    context 'with valid id' do
      it 'responds with a status code 200' do
        get :show, namespace_id: project.namespace, project_id: project, id: environment.id

        expect(response).to be_ok
      end
    end

    context 'with invalid id' do
      it 'responds with a status code 404' do
        get :show, namespace_id: project.namespace, project_id: project, id: 12345

        expect(response).to be_not_found
      end
    end
  end

  describe 'GET edit' do
    it 'responds with a status code 200' do
      get :edit, namespace_id: project.namespace, project_id: project, id: environment.id

      expect(response).to be_ok
    end
  end

  describe 'PATCH #update' do
    it 'responds with a 302' do
      patch :update, namespace_id: project.namespace, project_id:
                      project, id: environment.id, environment: { external_url: 'https://git.gitlab.com' }

      expect(response).to have_http_status(302)
    end
  end
end
