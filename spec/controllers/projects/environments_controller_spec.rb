require 'spec_helper'

describe Projects::EnvironmentsController do
  include ApiHelpers

  let(:environment) { create(:environment) }
  let(:project)     { environment.project }
  let(:user)        { create(:user) }

  before do
    project.team << [user, :master]

    sign_in(user)
  end

  describe 'GET index' do
    context 'when standardrequest has been made' do
      it 'responds with status code 200' do
        get :index, environment_params

        expect(response).to be_ok
      end
    end

    context 'when requesting JSON response' do
      it 'responds with correct JSON' do
        get :index, environment_params(format: :json)

        first_environment = json_response.first

        expect(first_environment).not_to be_empty
        expect(first_environment['name']). to eq environment.name
      end
    end
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

  def environment_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace,
                       project_id: project,
                       id: environment.id)
  end
end
