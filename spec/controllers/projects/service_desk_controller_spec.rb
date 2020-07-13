# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ServiceDeskController do
  let_it_be(:project) do
    create(:project, :private, :custom_repo, service_desk_enabled: true,
           files: { '.gitlab/issue_templates/service_desk.md' => 'template' })
  end

  let_it_be(:user) { create(:user) }

  before do
    allow(Gitlab::IncomingEmail).to receive(:enabled?) { true }
    allow(Gitlab::IncomingEmail).to receive(:supports_wildcard?) { true }

    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET service desk properties' do
    it 'returns service_desk JSON data' do
      get :show, params: { namespace_id: project.namespace.to_param, project_id: project }, format: :json

      expect(json_response["service_desk_address"]).to match(/\A[^@]+@[^@]+\z/)
      expect(json_response["service_desk_enabled"]).to be_truthy
      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when user is not project maintainer' do
      let(:guest) { create(:user) }

      it 'renders 404' do
        project.add_guest(guest)
        sign_in(guest)

        get :show, params: { namespace_id: project.namespace.to_param, project_id: project }, format: :json

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when issue template is present' do
      it 'returns template_file_missing as false' do
        create(:service_desk_setting, project: project, issue_template_key: 'service_desk')

        get :show, params: { namespace_id: project.namespace.to_param, project_id: project }, format: :json

        response_hash = Gitlab::Json.parse(response.body)
        expect(response_hash['template_file_missing']).to eq(false)
      end
    end

    context 'when issue template file becomes outdated' do
      it 'returns template_file_missing as true' do
        service = ServiceDeskSetting.new(project_id: project.id, issue_template_key: 'deleted')
        service.save!(validate: false)

        get :show, params: { namespace_id: project.namespace.to_param, project_id: project }, format: :json

        expect(json_response['template_file_missing']).to eq(true)
      end
    end
  end

  describe 'PUT service desk properties' do
    it 'toggles services desk incoming email' do
      project.update!(service_desk_enabled: false)

      put :update, params: { namespace_id: project.namespace.to_param,
                             project_id: project,
                             service_desk_enabled: true }, format: :json

      expect(json_response["service_desk_address"]).to be_present
      expect(json_response["service_desk_enabled"]).to be_truthy
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'sets issue_template_key' do
      put :update, params: { namespace_id: project.namespace.to_param,
                             project_id: project,
                             issue_template_key: 'service_desk' }, format: :json

      settings = project.service_desk_setting
      expect(settings).to be_present
      expect(settings.issue_template_key).to eq('service_desk')
      expect(json_response['template_file_missing']).to eq(false)
      expect(json_response['issue_template_key']).to eq('service_desk')
    end

    it 'returns an error when update of service desk settings fails' do
      put :update, params: { namespace_id: project.namespace.to_param,
                             project_id: project,
                             issue_template_key: 'invalid key' }, format: :json

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
      expect(json_response['message']).to eq('Issue template key is empty or does not exist')
    end

    context 'when user cannot admin the project' do
      let(:other_user) { create(:user) }

      it 'renders 404' do
        sign_in(other_user)
        put :update, params: { namespace_id: project.namespace.to_param, project_id: project, service_desk_enabled: true }, format: :json

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
