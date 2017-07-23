require 'spec_helper'

describe Projects::WikisController do
  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { create(:user) }

  describe 'POST #preview_markdown' do
    it 'renders json in a correct format' do
      sign_in(user)

      post :preview_markdown, namespace_id: project.namespace, project_id: project, id: 'page/path', text: '*Markdown* text'

      expect(JSON.parse(response.body).keys).to match_array(%w(body references))
    end
  end
end
