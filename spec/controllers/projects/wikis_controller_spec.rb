# frozen_string_literal: true

require 'spec_helper'

describe Projects::WikisController do
  let_it_be(:project) { create(:project, :public, :repository) }
  let(:user) { project.owner }
  let(:project_wiki) { ProjectWiki.new(project, user) }
  let(:wiki) { project_wiki.wiki }
  let(:wiki_title) { 'page title test' }

  before do
    create_page(wiki_title, 'hello world')

    sign_in(user)
  end

  after do
    destroy_page(wiki_title)
  end

  describe 'GET #new' do
    subject { get :new, params: { namespace_id: project.namespace, project_id: project } }

    it 'redirects to #show and appends a `random_title` param' do
      subject

      expect(response).to have_http_status(302)
      expect(Rails.application.routes.recognize_path(response.redirect_url)).to include(
        controller: 'projects/wikis',
        action: 'show'
      )
      expect(response.redirect_url).to match(/\?random_title=true\Z/)
    end
  end

  describe 'GET #pages' do
    subject { get :pages, params: { namespace_id: project.namespace, project_id: project, id: wiki_title } }

    it 'does not load the pages content' do
      expect(controller).to receive(:load_wiki).and_return(project_wiki)

      expect(project_wiki).to receive(:list_pages).twice.and_call_original

      subject
    end
  end

  describe 'GET #history' do
    before do
      allow(controller)
        .to receive(:can?)
        .with(any_args)
        .and_call_original

      # The :create_wiki permission is irrelevant to reading history.
      expect(controller)
        .not_to receive(:can?)
        .with(anything, :create_wiki, any_args)

      allow(controller)
        .to receive(:can?)
        .with(anything, :read_wiki, any_args)
        .and_return(allow_read_wiki)
    end

    shared_examples 'fetching history' do |expected_status|
      before do
        get :history, params: { namespace_id: project.namespace, project_id: project, id: wiki_title }
      end

      it "returns status #{expected_status}" do
        expect(response).to have_http_status(expected_status)
      end
    end

    it_behaves_like 'fetching history', :ok do
      let(:allow_read_wiki)   { true }

      it 'assigns @page_versions' do
        expect(assigns(:page_versions)).to be_present
      end
    end

    it_behaves_like 'fetching history', :not_found do
      let(:allow_read_wiki)   { false }
    end
  end

  describe 'GET #show' do
    render_views

    let(:random_title) { nil }

    subject { get :show, params: { namespace_id: project.namespace, project_id: project, id: id, random_title: random_title } }

    context 'when page exists' do
      let(:id) { wiki_title }

      it 'limits the retrieved pages for the sidebar' do
        expect(controller).to receive(:load_wiki).and_return(project_wiki)
        expect(project_wiki).to receive(:list_pages).with(limit: 15).and_call_original

        subject

        expect(response).to have_http_status(:ok)
        expect(assigns(:page).title).to eq(wiki_title)
      end

      context 'when page content encoding is invalid' do
        it 'sets flash error' do
          allow(controller).to receive(:valid_encoding?).and_return(false)

          subject

          expect(response).to have_http_status(:ok)
          expect(flash[:notice]).to eq(_('The content of this page is not encoded in UTF-8. Edits can only be made via the Git repository.'))
        end
      end
    end

    context 'when the page does not exist' do
      let(:id) { 'does not exist' }

      before do
        subject
      end

      it 'builds a new wiki page with the id as the title' do
        expect(assigns(:page).title).to eq(id)
      end

      context 'when a random_title param is present' do
        let(:random_title) { true }

        it 'builds a new wiki page with no title' do
          expect(assigns(:page).title).to be_empty
        end
      end
    end

    context 'when page is a file' do
      include WikiHelpers

      let(:id) { upload_file_to_wiki(project, user, file_name) }

      before do
        subject
      end

      context 'when file is an image' do
        let(:file_name) { 'dk.png' }

        it 'delivers the image' do
          expect(response.headers['Content-Disposition']).to match(/^inline/)
          expect(response.headers[Gitlab::Workhorse::DETECT_HEADER]).to eq "true"
        end

        context 'when file is a svg' do
          let(:file_name) { 'unsanitized.svg' }

          it 'delivers the image' do
            expect(response.headers['Content-Disposition']).to match(/^inline/)
            expect(response.headers[Gitlab::Workhorse::DETECT_HEADER]).to eq "true"
          end
        end
      end

      context 'when file is a pdf' do
        let(:file_name) { 'git-cheat-sheet.pdf' }

        it 'sets the content type to sets the content response headers' do
          expect(response.headers['Content-Disposition']).to match(/^inline/)
          expect(response.headers[Gitlab::Workhorse::DETECT_HEADER]).to eq "true"
        end
      end
    end
  end

  describe 'POST #preview_markdown' do
    it 'renders json in a correct format' do
      post :preview_markdown, params: { namespace_id: project.namespace, project_id: project, id: 'page/path', text: '*Markdown* text' }

      expect(json_response.keys).to match_array(%w(body references))
    end
  end

  describe 'GET #edit' do
    subject { get(:edit, params: { namespace_id: project.namespace, project_id: project, id: wiki_title }) }

    context 'when page content encoding is invalid' do
      it 'redirects to show' do
        allow(controller).to receive(:valid_encoding?).and_return(false)

        subject

        expect(response).to redirect_to(project_wiki_path(project, project_wiki.list_pages.first))
      end
    end

    context 'when page content encoding is valid' do
      render_views

      it 'shows the edit page' do
        subject

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(s_('Wiki|Edit Page'))
      end
    end
  end

  describe 'PATCH #update' do
    let(:new_title) { 'New title' }
    let(:new_content) { 'New content' }
    subject do
      patch(:update,
            params: {
              namespace_id: project.namespace,
              project_id: project,
              id: wiki_title,
              wiki: { title: new_title, content: new_content }
            })
    end

    context 'when page content encoding is invalid' do
      it 'redirects to show' do
        allow(controller).to receive(:valid_encoding?).and_return(false)

        subject
        expect(response).to redirect_to(project_wiki_path(project, project_wiki.list_pages.first))
      end
    end

    context 'when page content encoding is valid' do
      render_views

      it 'updates the page' do
        subject

        wiki_page = project_wiki.list_pages(load_content: true).first

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
