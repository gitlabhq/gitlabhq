# frozen_string_literal: true

require 'spec_helper'

describe Projects::MattermostsController do
  let!(:project) { create(:project) }
  let!(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET #new' do
    before do
      allow_next_instance_of(MattermostSlashCommandsService) do |instance|
        allow(instance).to receive(:list_teams).and_return([])
      end
    end

    it 'accepts the request' do
      get(:new,
          params: {
            namespace_id: project.namespace.to_param,
            project_id: project
          })

      expect(response).to have_gitlab_http_status(200)
    end
  end

  describe 'POST #create' do
    let(:mattermost_params) { { trigger: 'http://localhost:3000/trigger', team_id: 'abc' } }

    subject do
      post(:create,
           params: {
             namespace_id: project.namespace.to_param,
             project_id: project,
             mattermost: mattermost_params
           })
    end

    context 'no request can be made to mattermost' do
      it 'shows the error' do
        allow_next_instance_of(MattermostSlashCommandsService) do |instance|
          allow(instance).to receive(:configure).and_return([false, "error message"])
        end

        expect(subject).to redirect_to(new_project_mattermost_url(project))
      end
    end

    context 'the request is succesull' do
      before do
        allow_next_instance_of(Mattermost::Command) do |instance|
          allow(instance).to receive(:create).and_return('token')
        end
      end

      it 'redirects to the new page' do
        subject
        service = project.services.last

        expect(subject).to redirect_to(edit_project_service_url(project, service))
      end
    end
  end
end
