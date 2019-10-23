# frozen_string_literal: true

require 'spec_helper'

describe Projects::WikiPagesController do
  set(:project) { create(:project, :public, :repository) }
  let(:user) { project.owner }
  let(:project_wiki) { ProjectWiki.new(project, user) }
  let(:wiki) { project_wiki.wiki }
  let(:wiki_title) { 'page-title-test' }
  let(:parent_ids) { { namespace_id: project.namespace.path, project_id: project.name } }
  let(:redirect_destination) { Rails.application.routes.recognize_path(response.redirect_url) }

  before do
    create_page(wiki_title, 'hello world')

    sign_in(user)
  end

  after do
    destroy_page(wiki_title)
  end

  def helper
    Helper.instance
  end

  class Helper
    include Singleton
    include ActionView::Helpers::UrlHelper
  end

  describe 'GET #new' do
    subject { get :new, params: parent_ids }

    it 'redirects to #show and appends a `random_title` param' do
      subject

      expect(response).to have_http_status(302)

      expect(redirect_destination)
        .to include(parent_ids.merge(controller: 'projects/wiki_pages', action: 'show'))

      expect(response.redirect_url).to match(/\?random_title=true\Z/)
    end
  end

  describe 'GET #show' do
    render_views
    let(:requested_wiki_page) { wiki_title }
    let(:random_title) { nil }

    subject do
      get :show, params: {
        namespace_id: project.namespace,
        project_id: project,
        id: requested_wiki_page,
        random_title: random_title
      }
    end

    context 'when the wiki repo cannot be created' do
      before do
        allow(controller).to receive(:load_wiki) { raise ProjectWiki::CouldNotCreateWikiError }
      end

      it 'redirects to the project path' do
        headers = { 'Location' => a_string_ending_with(Gitlab::Routing.url_helpers.project_path(project)) }

        subject

        expect(response).to be_redirect
        expect(response.header.to_hash).to include(headers)
      end
    end

    context 'when the page exists' do
      it 'limits the retrieved pages for the sidebar' do
        expect(controller).to receive(:load_wiki).and_return(project_wiki)

        # Sidebar entries
        expect(project_wiki).to receive(:list_pages).with(limit: 15).and_call_original

        subject

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(wiki_title)
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

    context 'when the page does not exist' do
      let(:requested_wiki_page) { 'this-page-does-not-yet-exist' }

      context 'the current user can create wiki pages' do
        it { is_expected.to render_template('edit') }

        it 'makes a call to see if the wiki is empty' do
          expect(controller).to receive(:load_wiki).and_return(project_wiki)
          expect(project_wiki).to receive(:list_pages).once.with(limit: anything).and_call_original
          expect(project_wiki).to receive(:list_pages).with(limit: 1).and_call_original
          subject
        end

        describe 'assigned title' do
          shared_examples :wiki_page_with_correct_title do
            it 'assigns the correct title' do
              subject

              expect(assigns(:page)).to have_attributes(title: assigned_title)
            end
          end

          context 'random_title is absent' do
            let(:random_title) { nil }

            it_behaves_like :wiki_page_with_correct_title do
              let(:assigned_title) { WikiPage.unhyphenize(requested_wiki_page) }
            end
          end

          context 'random_title is present' do
            let(:random_title) { true }

            it_behaves_like :wiki_page_with_correct_title do
              let(:assigned_title) { be_empty }
            end
          end
        end
      end

      context 'the current user cannot create wiki pages' do
        before do
          forbid_controller_ability! :create_wiki
        end
        it { is_expected.to render_template('missing_page') }
      end
    end

    context 'when page is a file' do
      include WikiHelpers

      let(:path) { upload_file_to_wiki(project, user, file_name) }

      before do
        get :show, params: { namespace_id: project.namespace, project_id: project, id: path }
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
    let(:page_id) { 'page/path' }
    let(:markdown_text) { '*Markdown* text' }
    let(:wiki_page) { create(:wiki_page, wiki: project_wiki, attrs: { title: wiki_title }) }
    let(:processed_md) { json_response.fetch('body') }

    let(:preview_params) do
      { namespace_id: project.namespace, project_id: project, id: wiki_page.slug, text: markdown_text }
    end

    before do
      post :preview_markdown, params: preview_params
    end

    it 'renders json in a correct format' do
      expect(response).to have_http_status(:ok)
      expect(json_response).to include('body' => String, 'references' => Hash)
    end

    describe 'double brackets within backticks' do
      let(:markdown_text) do
        <<-HEREDOC
          `[[do_not_linkify]]`
          ```
          [[also_do_not_linkify]]
          ```
        HEREDOC
      end

      it "does not linkify double brackets inside code blocks as expected" do
        expect(processed_md).to include('[[do_not_linkify]]', '[[also_do_not_linkify]]')
      end
    end

    describe 'link re-writing' do
      let(:links) do
        [
          { text: 'regular link',    path: 'regular' },
          { text: 'relative link 1', path: '../relative' },
          { text: 'relative link 2', path: './relative' },
          { text: 'relative link 3', path: './e/f/relative' },
          { text: 'spaced link',     path: 'title with spaces' }
        ]
      end

      shared_examples :wiki_link_rewriter do
        let(:markdown_text) { links.map { |text:, path:| "[#{text}](#{path})" }.join("\n") }
        let(:expected_links) do
          links.zip(paths).map do |(link, path)|
            helper.link_to(link[:text], "#{project_wiki.wiki_page_path}/#{path}")
          end
        end

        it 'processes the links correctly' do
          expect(processed_md).to include(*expected_links)
        end
      end

      context 'the current page has spaces in its title' do
        let(:wiki_title) { 'page a/page b/page c/page d' }
        it_behaves_like :wiki_link_rewriter do
          let(:paths) do
            ['regular',
             'page-a/page-b/relative',
             'page-a/page-b/page-c/relative',
             'page-a/page-b/page-c/e/f/relative',
             'title%20with%20spaces']
          end
        end
      end

      context 'the current page has an unproblematic title' do
        let(:wiki_title) { 'a/b/c/d' }
        it_behaves_like :wiki_link_rewriter do
          let(:paths) do
            ['regular', 'a/b/relative', 'a/b/c/relative', 'a/b/c/e/f/relative', 'title%20with%20spaces']
          end
        end
      end

      context "when there are hyphens in the page name" do
        let(:wiki_title) { 'page-a/page-b/page-c/page-d' }
        it_behaves_like :wiki_link_rewriter do
          let(:paths) do
            ['regular',
             'page-a/page-b/relative',
             'page-a/page-b/page-c/relative',
             'page-a/page-b/page-c/e/f/relative',
             'title%20with%20spaces']
          end
        end
      end
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
        expect(response.body).to include('Edit Page')
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
              wiki_page: { title: new_title, content: new_content }
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

  private

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
