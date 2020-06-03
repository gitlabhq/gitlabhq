# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TemplatesController do
  let(:project) { create(:project, :repository, :private) }
  let(:user) { create(:user) }
  let(:file_path_1) { '.gitlab/issue_templates/issue_template.md' }
  let(:file_path_2) { '.gitlab/merge_request_templates/merge_request_template.md' }
  let!(:file_1) { project.repository.create_file(user, file_path_1, 'issue content', message: 'message', branch_name: 'master') }
  let!(:file_2) { project.repository.create_file(user, file_path_2, 'merge request content', message: 'message', branch_name: 'master') }

  describe '#show' do
    shared_examples 'renders issue templates as json' do
      it do
        get(:show, params: { namespace_id: project.namespace, template_type: 'issue', key: 'issue_template', project_id: project }, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq('issue_template')
        expect(json_response['content']).to eq('issue content')
      end
    end

    shared_examples 'renders merge request templates as json' do
      it do
        get(:show, params: { namespace_id: project.namespace, template_type: 'merge_request', key: 'merge_request_template', project_id: project }, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq('merge_request_template')
        expect(json_response['content']).to eq('merge request content')
      end
    end

    shared_examples 'renders 404 when requesting an issue template' do
      it do
        get(:show, params: { namespace_id: project.namespace, template_type: 'issue', key: 'issue_template', project_id: project }, format: :json)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    shared_examples 'renders 404 when requesting a merge request template' do
      it do
        get(:show, params: { namespace_id: project.namespace, template_type: 'merge_request', key: 'merge_request_template', project_id: project }, format: :json)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    shared_examples 'renders 404 when params are invalid' do
      it 'does not route when the template type is invalid' do
        expect do
          get(:show, params: { namespace_id: project.namespace, template_type: 'invalid_type', key: 'issue_template', project_id: project }, format: :json)
        end.to raise_error(ActionController::UrlGenerationError)
      end

      it 'renders 404 when the format type is invalid' do
        get(:show, params: { namespace_id: project.namespace, template_type: 'issue', key: 'issue_template', project_id: project }, format: :html)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'renders 404 when the key is unknown' do
        get(:show, params: { namespace_id: project.namespace, template_type: 'issue', key: 'unknown_template', project_id: project }, format: :json)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the user is not a member of the project' do
      before do
        sign_in(user)
      end

      include_examples 'renders 404 when requesting an issue template'
      include_examples 'renders 404 when requesting a merge request template'
      include_examples 'renders 404 when params are invalid'
    end

    context 'when user is a member of the project' do
      before do
        project.add_developer(user)
        sign_in(user)
      end

      include_examples 'renders issue templates as json'
      include_examples 'renders merge request templates as json'
      include_examples 'renders 404 when params are invalid'
    end

    context 'when user is a guest of the project' do
      before do
        project.add_guest(user)
        sign_in(user)
      end

      include_examples 'renders issue templates as json'
      include_examples 'renders 404 when requesting a merge request template'
      include_examples 'renders 404 when params are invalid'
    end
  end

  describe '#names' do
    before do
      project.add_developer(user)
      sign_in(user)
    end

    shared_examples 'template names request' do
      it 'returns the template names' do
        get(:names, params: { namespace_id: project.namespace, template_type: template_type, project_id: project }, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.size).to eq(1)
        expect(json_response[0]['name']).to eq(expected_template_name)
      end

      it 'fails for user with no access' do
        other_user = create(:user)
        sign_in(other_user)

        get(:names, params: { namespace_id: project.namespace, template_type: template_type, project_id: project }, format: :json)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when querying for issue templates' do
      it_behaves_like 'template names request' do
        let(:template_type) { 'issue' }
        let(:expected_template_name) { 'issue_template' }
      end
    end

    context 'when querying for merge_request templates' do
      it_behaves_like 'template names request' do
        let(:template_type) { 'merge_request' }
        let(:expected_template_name) { 'merge_request_template' }
      end
    end
  end
end
