require 'spec_helper'

describe Projects::ServiceDeskController do
  let(:project) { create(:project_empty_repo, :private) }
  let(:user)    { create(:user, admin: true) }

  before do
    allow_any_instance_of(License).to receive(:add_on?).and_call_original
    allow_any_instance_of(License).to receive(:add_on?).with('GitLab_ServiceDesk') { true }
    project.update(service_desk_enabled: true)
    project.add_master(user)
    sign_in(user)
  end

  describe 'GET service desk properties' do
    it 'returns service_desk JSON data' do
      get :show, namespace_id: project.namespace.to_param, project_id: project, format: :json

      body = JSON.parse(response.body)
      expect(body["service_desk_address"]).to match(/\A[^@]+@[^@]+\z/)
      expect(body["service_desk_enabled"]).to be_truthy
      expect(response.status).to eq(200)
    end

    context 'when user is not project master' do
      let(:guest) { create(:user) }

      it 'renders 404' do
        project.add_guest(guest)
        sign_in(guest)

        get :show, namespace_id: project.namespace.to_param, project_id: project, format: :json

        expect(response.status).to eq(404)
      end
    end
  end

  describe 'PUT service desk properties' do
    it 'toggles services desk incoming email' do
      project.update(service_desk_enabled: true)
      old_address = project.service_desk_address
      project.update(service_desk_enabled: false)

      put :update, namespace_id: project.namespace.to_param, project_id: project, service_desk_enabled: true, format: :json

      body = JSON.parse(response.body)
      expect(body["service_desk_address"]).to be_present
      expect(body["service_desk_address"]).not_to eq(old_address)
      expect(body["service_desk_enabled"]).to be_truthy
      expect(response.status).to eq(200)
    end

    context 'when user cannot admin the project' do
      let(:other_user) { create(:user) }

      it 'renders 404' do
        sign_in(other_user)
        put :update, namespace_id: project.namespace.to_param, project_id: project, service_desk_enabled: true, format: :json

        expect(response.status).to eq(404)
      end
    end
  end
end
