require 'spec_helper'

describe Projects::WikisController do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.owner }
  let(:project_wiki) { ProjectWiki.new(project, user) }
  let(:wiki) { project_wiki.wiki }
  let(:wiki_title) { 'page-title-test' }

  before do
    create_page(wiki_title, 'hello world')

    sign_in(user)
  end

  after do
    destroy_page(wiki_title)
  end

  describe 'GET #show' do
    render_views

    subject { get :show, namespace_id: project.namespace, project_id: project, id: wiki_title }

    context 'when page content encoding is invalid' do
      it 'limits the retrieved pages for the sidebar' do
        expect(controller).to receive(:load_wiki).and_return(project_wiki)

        # empty? call
        expect(project_wiki).to receive(:pages).with(limit: 1).and_call_original
        # Sidebar entries
        expect(project_wiki).to receive(:pages).with(limit: 15).and_call_original

        subject

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(wiki_title)
      end
    end

    context 'when page content encoding is invalid' do
      it 'sets flash error' do
        allow(controller).to receive(:valid_encoding?).and_return(false)

        subject

        expect(response).to have_http_status(:ok)
        expect(flash[:notice]).to eq 'The content of this page is not encoded in UTF-8. Edits can only be made via the Git repository.'
      end
    end
  end

  describe 'POST #preview_markdown' do
    it 'renders json in a correct format' do
      post :preview_markdown, namespace_id: project.namespace, project_id: project, id: 'page/path', text: '*Markdown* text'

      expect(JSON.parse(response.body).keys).to match_array(%w(body references))
    end
  end

  describe 'GET #edit' do
    subject { get(:edit, namespace_id: project.namespace, project_id: project, id: wiki_title) }

    context 'when page content encoding is invalid' do
      it 'redirects to show' do
        allow(controller).to receive(:valid_encoding?).and_return(false)

        subject

        expect(response).to redirect_to(project_wiki_path(project, project_wiki.pages.first))
      end
    end

    context 'when page content encoding is valid' do
      render_views

      it 'shows the edit page' do
        subject

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Edit Page')
      end
    end
  end

  describe 'PATCH #update' do
    let(:new_title) { 'New title' }
    let(:new_content) { 'New content' }
    subject do
      patch(:update,
            namespace_id: project.namespace,
            project_id: project,
            id: wiki_title,
            wiki: { title: new_title, content: new_content })
    end

    context 'when page content encoding is invalid' do
      it 'redirects to show' do
        allow(controller).to receive(:valid_encoding?).and_return(false)

        subject
        expect(response).to redirect_to(project_wiki_path(project, project_wiki.pages.first))
      end
    end

    context 'when page content encoding is valid' do
      render_views

      it 'updates the page' do
        subject

        wiki_page = project_wiki.pages.first

        expect(wiki_page.title).to eq new_title
        expect(wiki_page.content).to eq new_content
      end
    end
  end

  def create_page(name, content)
    wiki.write_page(name, :markdown, content, commit_details(name))
  end

  def commit_details(name)
    Gitlab::Git::Wiki::CommitDetails.new(user.id, user.username, user.name, user.email, "created page #{name}")
  end

  def destroy_page(title, dir = '')
    page = wiki.page(title: title, dir: dir)
    project_wiki.delete_page(page, "test commit")
  end
end
