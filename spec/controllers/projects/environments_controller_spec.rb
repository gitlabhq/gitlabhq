require 'spec_helper'

describe Projects::EnvironmentsController do
  let(:environment) { create(:environment) }
  let(:project)     { environment.project }
  let(:user)        { create(:user) }

  before do
    project.team << [user, :master]

    sign_in(user)
  end

  describe 'GET show' do
    context 'with valid id' do
      it 'responds with a status code 200' do
        get :show, environment_params

        expect(response).to be_ok
      end
    end

    context 'with invalid id' do
      it 'responds with a status code 404' do
        params = environment_params
        params[:id] = 12345
        get :show, params

        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'GET edit' do
    it 'responds with a status code 200' do
      get :edit, environment_params

      expect(response).to be_ok
    end
  end

  describe 'PATCH #update' do
    it 'responds with a 302' do
      patch_params = environment_params.merge(environment: { external_url: 'https://git.gitlab.com' })
      patch :update, patch_params

      expect(response).to have_http_status(302)
    end
  end

  def environment_params
    {
      namespace_id: project.namespace,
      project_id: project,
      id: environment.id
    }
  end
end
