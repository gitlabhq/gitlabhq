require 'spec_helper'

describe Projects::MattermostsController do
  let!(:project) { create(:empty_project) }
  let!(:user) { create(:user) }

  before do
    project.team << [user, :master]
    sign_in(user)
  end

  describe 'GET #new' do
    before do
      get(:new,
          namespace_id: project.namespace.to_param,
          project_id: project.to_param)
    end

    it 'accepts the request' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST #create' do
    let(:mattermost_params) { { trigger: 'http://localhost:3000/trigger', team_id: 'abc' } }

    subject do
      post(:create,
           namespace_id: project.namespace.to_param,
           project_id: project.to_param,
           mattermost: mattermost_params)
    end

    context 'no request can be made to mattermost' do
      it 'shows the error' do
        expect(controller).to set_flash[:alert].to /\AFailed to open TCP connection to/
      end
    end

    context 'the request is succesull' do
      before do
        allow_any_instance_of(Mattermost::Command).to receive(:create).and_return('token')
      end

      it 'redirects to the new page' do
        subject
        service = project.services.last

        expect(subject).to redirect_to(edit_namespace_project_service_url(project.namespace, project, service))
      end
    end
  end
end
