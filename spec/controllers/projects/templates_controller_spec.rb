require 'spec_helper'

describe Projects::TemplatesController do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:file_path_1) { '.gitlab/issue_templates/bug.md' }
  let(:body) { JSON.parse(response.body) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  before do
    project.add_user(user, Gitlab::Access::MASTER)
    project.repository.create_file(user, file_path_1, 'something valid',
      message: 'test 3', branch_name: 'master')
  end

  describe '#show' do
    it 'renders template name and content as json' do
      get(:show, namespace_id: project.namespace.to_param, template_type: "issue", key: "bug", project_id: project, format: :json)

      expect(response.status).to eq(200)
      expect(body["name"]).to eq("bug")
      expect(body["content"]).to eq("something valid")
    end

    it 'renders 404 when unauthorized' do
      sign_in(user2)
      get(:show, namespace_id: project.namespace.to_param, template_type: "issue", key: "bug", project_id: project, format: :json)

      expect(response.status).to eq(404)
    end

    it 'renders 404 when template type is not found' do
      sign_in(user)
      get(:show, namespace_id: project.namespace.to_param, template_type: "dont_exist", key: "bug", project_id: project, format: :json)

      expect(response.status).to eq(404)
    end

    it 'renders 404 without errors' do
      sign_in(user)
      expect { get(:show, namespace_id: project.namespace.to_param, template_type: "dont_exist", key: "bug", project_id: project, format: :json) }.not_to raise_error
    end
  end
end
