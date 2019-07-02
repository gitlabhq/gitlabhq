# frozen_string_literal: true

require 'spec_helper'

describe Projects::TemplatesController do
  let(:project) { create(:project, :repository, :private) }
  let(:user) { create(:user) }
  let(:file_path_1) { '.gitlab/issue_templates/issue_template.md' }
  let(:file_path_2) { '.gitlab/merge_request_templates/merge_request_template.md' }
  let(:body) { JSON.parse(response.body) }
  let!(:file_1) { project.repository.create_file(user, file_path_1, 'issue content', message: 'message', branch_name: 'master') }
  let!(:file_2) { project.repository.create_file(user, file_path_2, 'merge request content', message: 'message', branch_name: 'master') }

  describe '#show' do
    shared_examples 'renders issue templates as json' do
      it do
        get(:show, params: { namespace_id: project.namespace, template_type: 'issue', key: 'issue_template', project_id: project }, format: :json)

        expect(response.status).to eq(200)
        expect(body['name']).to eq('issue_template')
        expect(body['content']).to eq('issue content')
      end
    end

    shared_examples 'renders merge request templates as json' do
      it do
        get(:show, params: { namespace_id: project.namespace, template_type: 'merge_request', key: 'merge_request_template', project_id: project }, format: :json)

        expect(response.status).to eq(200)
        expect(body['name']).to eq('merge_request_template')
        expect(body['content']).to eq('merge request content')
      end
    end

    shared_examples 'renders 404 when requesting an issue template' do
      it do
        get(:show, params: { namespace_id: project.namespace, template_type: 'issue', key: 'issue_template', project_id: project }, format: :json)

        expect(response.status).to eq(404)
      end
    end

    shared_examples 'renders 404 when requesting a merge request template' do
      it do
        get(:show, params: { namespace_id: project.namespace, template_type: 'merge_request', key: 'merge_request_template', project_id: project }, format: :json)

        expect(response.status).to eq(404)
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

        expect(response.status).to eq(404)
      end

      it 'renders 404 when the key is unknown' do
        get(:show, params: { namespace_id: project.namespace, template_type: 'issue', key: 'unknown_template', project_id: project }, format: :json)

        expect(response.status).to eq(404)
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
end
