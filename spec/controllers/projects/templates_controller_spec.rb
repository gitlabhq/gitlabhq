# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TemplatesController do
  let(:project) { create(:project, :repository, :private) }
  let(:user) { create(:user) }
  let(:issue_template_path_1) { '.gitlab/issue_templates/issue_template_1.md' }
  let(:issue_template_path_2) { '.gitlab/issue_templates/issue_template_2.md' }
  let(:merge_request_template_path_1) { '.gitlab/merge_request_templates/merge_request_template_1.md' }
  let(:merge_request_template_path_2) { '.gitlab/merge_request_templates/merge_request_template_2.md' }
  let!(:issue_template_file_1) { project.repository.create_file(user, issue_template_path_1, 'issue content 1', message: 'message 1', branch_name: 'master') }
  let!(:issue_template_file_2) { project.repository.create_file(user, issue_template_path_2, 'issue content 2', message: 'message 2', branch_name: 'master') }
  let!(:merge_request_template_file_1) { project.repository.create_file(user, merge_request_template_path_1, 'merge request content 1', message: 'message 1', branch_name: 'master') }
  let!(:merge_request_template_file_2) { project.repository.create_file(user, merge_request_template_path_2, 'merge request content 2', message: 'message 2', branch_name: 'master') }
  let(:expected_issue_template_1) { { 'key' => 'issue_template_1', 'name' => 'issue_template_1', 'content' => 'issue content 1' } }
  let(:expected_issue_template_2) { { 'key' => 'issue_template_2', 'name' => 'issue_template_2', 'content' => 'issue content 2' } }
  let(:expected_merge_request_template_1) { { 'key' => 'merge_request_template_1', 'name' => 'merge_request_template_1', 'content' => 'merge request content 1' } }
  let(:expected_merge_request_template_2) { { 'key' => 'merge_request_template_2', 'name' => 'merge_request_template_2', 'content' => 'merge request content 2' } }

  describe '#index' do
    before do
      project.add_developer(user)
      sign_in(user)
    end

    shared_examples 'templates request' do
      it 'returns the templates' do
        get(:index, params: { namespace_id: project.namespace, template_type: template_type, project_id: project }, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to match(expected_templates)
      end

      it 'fails for user with no access' do
        other_user = create(:user)
        sign_in(other_user)

        get(:index, params: { namespace_id: project.namespace, template_type: template_type, project_id: project }, format: :json)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when querying for issue templates' do
      it_behaves_like 'templates request' do
        let(:template_type) { 'issue' }
        let(:expected_templates) { [expected_issue_template_1, expected_issue_template_2] }
      end
    end

    context 'when querying for merge_request templates' do
      it_behaves_like 'templates request' do
        let(:template_type) { 'merge_request' }
        let(:expected_templates) { [expected_merge_request_template_1, expected_merge_request_template_2] }
      end
    end
  end

  describe '#show' do
    shared_examples 'renders issue templates as json' do
      let(:expected_issue_template) { expected_issue_template_2 }

      it do
        get(:show, params: { namespace_id: project.namespace, template_type: 'issue', key: 'issue_template_2', project_id: project }, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to match(expected_issue_template)
      end
    end

    shared_examples 'renders merge request templates as json' do
      let(:expected_merge_request_template) { expected_merge_request_template_2 }

      it do
        get(:show, params: { namespace_id: project.namespace, template_type: 'merge_request', key: 'merge_request_template_2', project_id: project }, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to match(expected_merge_request_template)
      end
    end

    shared_examples 'renders 404 when requesting an issue template' do
      it do
        get(:show, params: { namespace_id: project.namespace, template_type: 'issue', key: 'issue_template_1', project_id: project }, format: :json)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    shared_examples 'renders 404 when requesting a merge request template' do
      it do
        get(:show, params: { namespace_id: project.namespace, template_type: 'merge_request', key: 'merge_request_template_1', project_id: project }, format: :json)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    shared_examples 'raises error when template type is invalid' do
      it 'does not route when the template type is invalid' do
        expect do
          get(:show, params: { namespace_id: project.namespace, template_type: 'invalid_type', key: 'issue_template_1', project_id: project }, format: :json)
        end.to raise_error(ActionController::UrlGenerationError)
      end
    end

    shared_examples 'renders 404 when params are invalid' do
      it 'renders 404 when the format type is invalid' do
        get(:show, params: { namespace_id: project.namespace, template_type: 'issue', key: 'issue_template_1', project_id: project }, format: :html)

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
    end

    context 'when user is a member of the project' do
      before do
        project.add_developer(user)
        sign_in(user)
      end

      include_examples 'renders issue templates as json'
      include_examples 'renders merge request templates as json'

      context 'when params are invalid' do
        include_examples 'raises error when template type is invalid'
        include_examples 'renders 404 when params are invalid'
      end
    end

    context 'when user is a guest of the project' do
      before do
        project.add_guest(user)
        sign_in(user)
      end

      include_examples 'renders issue templates as json'
      include_examples 'renders 404 when requesting a merge request template'
    end
  end

  describe '#names' do
    before do
      project.add_developer(user)
      sign_in(user)
    end

    shared_examples 'template names request' do
      it 'returns the template names', :aggregate_failures do
        get(:names, params: { namespace_id: project.namespace, template_type: template_type, project_id: project }, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['Project Templates'].size).to eq(2)
        expect(json_response['Project Templates'].map { |x| x.slice('name') }).to match(expected_template_names)
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
        let(:expected_template_names) { [{ 'name' => 'issue_template_1' }, { 'name' => 'issue_template_2' }] }
      end
    end

    context 'when querying for merge_request templates' do
      it_behaves_like 'template names request' do
        let(:template_type) { 'merge_request' }
        let(:expected_template_names) { [{ 'name' => 'merge_request_template_1' }, { 'name' => 'merge_request_template_2' }] }
      end
    end
  end
end
