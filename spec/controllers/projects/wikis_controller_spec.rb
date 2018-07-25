require 'spec_helper'

describe Projects::WikisController do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { create(:user) }
  let(:wiki) { ProjectWiki.new(project, user) }

  describe 'GET #show' do
    let(:wiki_title) { 'page-title-test' }

    render_views

    before do
      create_page(wiki_title, 'hello world')
    end

    it 'limits the retrieved pages for the sidebar' do
      sign_in(user)

      expect(controller).to receive(:load_wiki).and_return(wiki)

      # empty? call
      expect(wiki).to receive(:pages).with(limit: 1).and_call_original
      # Sidebar entries
      expect(wiki).to receive(:pages).with(limit: 15).and_call_original

      get :show, namespace_id: project.namespace, project_id: project, id: wiki_title

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(wiki_title)
    end
  end

  describe 'POST #preview_markdown' do
    it 'renders json in a correct format' do
      sign_in(user)

      post :preview_markdown, namespace_id: project.namespace, project_id: project, id: 'page/path', text: '*Markdown* text'

      expect(JSON.parse(response.body).keys).to match_array(%w(body references))
    end
  end

  def create_page(name, content)
    project.wiki.wiki.write_page(name, :markdown, content, commit_details(name))
  end

  def commit_details(name)
    Gitlab::Git::Wiki::CommitDetails.new(user.id, user.username, user.name, user.email, "created page #{name}")
  end
end
