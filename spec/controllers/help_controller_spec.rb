# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HelpController do
  include StubVersion
  include DocUrlHelper

  let(:user) { create(:user) }

  shared_examples 'documentation pages local render' do
    it 'renders HTML' do
      aggregate_failures do
        is_expected.to render_template('help/show')
        expect(response.media_type).to eq 'text/html'
      end
    end
  end

  shared_examples 'documentation pages redirect' do |documentation_base_url|
    let(:gitlab_version) { version }

    before do
      stub_version(gitlab_version, 'ignored_revision_value')
    end

    it 'redirects user to custom documentation url with a specified version' do
      is_expected.to redirect_to(doc_url(documentation_base_url))
    end

    context 'when it is a pre-release' do
      let(:gitlab_version) { '13.4.0-pre' }

      it 'redirects user to custom documentation url without a version' do
        is_expected.to redirect_to(doc_url_without_version(documentation_base_url))
      end
    end
  end

  before do
    sign_in(user)
  end

  describe 'GET #index' do
    context 'with absolute url' do
      it 'keeps the URL absolute' do
        stub_doc_file_read(content: "[API](/api/README.md)")

        get :index

        expect(assigns[:help_index]).to eq '[API](/api/README.md)'
      end
    end

    context 'with relative url' do
      it 'prefixes it with /help/' do
        stub_doc_file_read(content: "[API](api/README.md)")

        get :index

        expect(assigns[:help_index]).to eq '[API](/help/api/README.md)'
      end
    end

    context 'when url is an external link' do
      it 'does not change it' do
        stub_doc_file_read(content: "[external](https://some.external.link)")

        get :index

        expect(assigns[:help_index]).to eq '[external](https://some.external.link)'
      end
    end

    context 'when relative url with external on same line' do
      it 'prefix it with /help/' do
        stub_doc_file_read(content: "[API](api/README.md) [external](https://some.external.link)")

        get :index

        expect(assigns[:help_index]).to eq '[API](/help/api/README.md) [external](https://some.external.link)'
      end
    end

    context 'when relative url with http:// in query' do
      it 'prefix it with /help/' do
        stub_doc_file_read(content: "[API](api/README.md?go=https://example.com/)")

        get :index

        expect(assigns[:help_index]).to eq '[API](/help/api/README.md?go=https://example.com/)'
      end
    end

    context 'when mailto URL' do
      it 'do not change it' do
        stub_doc_file_read(content: "[report bug](mailto:bugs@example.com)")

        get :index

        expect(assigns[:help_index]).to eq '[report bug](mailto:bugs@example.com)'
      end
    end

    context 'when protocol-relative link' do
      it 'do not change it' do
        stub_doc_file_read(content: "[protocol-relative](//example.com)")

        get :index

        expect(assigns[:help_index]).to eq '[protocol-relative](//example.com)'
      end
    end

    context 'restricted visibility set to public' do
      before do
        sign_out(user)

        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      it 'redirects to sign_in path' do
        get :index

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when two factor is required' do
      before do
        stub_two_factor_required
      end

      it 'does not redirect to two factor auth' do
        get :index

        expect(response).not_to redirect_to(profile_two_factor_auth_path)
      end
    end

    context 'when requesting help index (underscore prefix test)' do
      subject { get :index }

      before do
        stub_application_setting(help_page_documentation_base_url: '')
      end

      context 'and the doc/index.md file exists' do
        it 'returns index.md' do
          expect(subject).to be_successful
          expect(assigns[:help_index]).to include('Explore the different areas of the documentation')
        end
      end

      context 'but the doc/index.md file does not exist' do
        it 'returns _index.md' do
          stub_doc_file_read(content: '_index.md content', file_name: '_index.md')

          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(Rails.root.join('doc/index.md').to_s).and_return(false)
          allow(File).to receive(:exist?).with(Rails.root.join('doc/_index.md').to_s).and_return(true)

          expect(subject).to be_successful
          expect(assigns[:help_index]).to eq '_index.md content'
        end
      end
    end

    context 'when requesting help index (frontmatter test)' do
      subject { get :index }

      before do
        stub_application_setting(help_page_documentation_base_url: '')
        stub_doc_file_read(content: content)
      end

      context 'and the doc/index.md file has the level 1 heading in frontmatter' do
        let(:content) { "---\ntitle: Test heading\n---\n\nTest content" }

        it 'returns content with title in Markdown' do
          expect(subject).to be_successful
          expect(assigns[:help_index]).to eq "# Test heading\n\nTest content"
        end
      end

      context 'and the doc/index.md file has the level 1 heading in Markdown' do
        let(:content) { "# Test heading\n\nTest content" }

        it 'returns content with title in Markdown' do
          expect(subject).to be_successful
          expect(assigns[:help_index]).to eq "# Test heading\n\nTest content"
        end
      end
    end
  end

  describe 'GET #drawers' do
    subject { get :drawers, params: { markdown_file: path } }

    context 'when requested file exists' do
      let(:path) { 'user/ssh' }
      let(:file_name) { "#{path}.md" }

      before do
        subject
      end

      it 'assigns variables', :aggregate_failures do
        expect(assigns[:path]).not_to be_empty
        expect(assigns[:clean_path]).not_to be_empty
      end

      it 'renders HTML', :aggregate_failures do
        is_expected.to render_template('help/drawers')
        expect(response.media_type).to eq 'text/html'
      end
    end

    context 'when requested file is missing' do
      let(:path) { 'foo/bar' }

      it 'renders not found' do
        subject

        expect(response).to be_not_found
      end
    end
  end

  describe 'GET #show' do
    context 'for Markdown formats' do
      subject { get :show, params: { path: path }, format: :md }

      let(:path) { 'user/ssh' }

      context 'when requested file exists' do
        before do
          stub_doc_file_read(file_name: 'user/ssh.md', content: fixture_file('blockquote_fence_legacy_after.md'))
          stub_application_setting(help_page_documentation_base_url: '')

          subject
        end

        it 'assigns to @markdown' do
          expect(assigns[:markdown]).not_to be_empty
        end

        it_behaves_like 'documentation pages local render'

        context 'when two factor is required' do
          before do
            stub_two_factor_required
          end

          it 'does not redirect to two factor auth' do
            expect(response).not_to redirect_to(profile_two_factor_auth_path)
          end
        end
      end

      context 'when a custom help_page_documentation_url is set in database' do
        before do
          stub_application_setting(help_page_documentation_base_url: 'https://in-db.gitlab.com')
        end

        it_behaves_like 'documentation pages redirect', 'https://in-db.gitlab.com'
      end

      context 'when a custom help_page_documentation_url is set in configuration file' do
        let(:host) { 'https://in-yaml.gitlab.com' }
        let(:docs_enabled) { true }

        before do
          allow(Settings).to receive(:gitlab_docs) { double(enabled: docs_enabled, host: host) }
        end

        it_behaves_like 'documentation pages redirect', 'https://in-yaml.gitlab.com'

        context 'when gitlab_docs is disabled' do
          let(:docs_enabled) { false }

          it_behaves_like 'documentation pages redirect', 'https://docs.gitlab.com'
        end

        context 'when host is missing' do
          let(:host) { nil }

          it_behaves_like 'documentation pages redirect', 'https://docs.gitlab.com'
        end
      end

      context 'when help_page_documentation_url is set in both db and configuration file' do
        before do
          stub_application_setting(help_page_documentation_base_url: 'https://in-db.gitlab.com')
          allow(Settings).to receive(:gitlab_docs) { double(enabled: true, host: 'https://in-yaml.gitlab.com') }
        end

        it_behaves_like 'documentation pages redirect', 'https://in-yaml.gitlab.com'
      end

      context 'when help_page_documentation_url has a trailing slash' do
        before do
          allow(Settings).to receive(:gitlab_docs) { double(enabled: true, host: 'https://in-yaml.gitlab.com/') }
        end

        it_behaves_like 'documentation pages redirect', 'https://in-yaml.gitlab.com'
      end

      context 'when requested file is missing' do
        before do
          stub_application_setting(help_page_documentation_base_url: '')
        end

        it 'renders not found' do
          get :show, params: { path: 'foo/bar' }, format: :md
          expect(response).to be_not_found
        end
      end
    end

    context 'for image formats' do
      context 'when requested file exists' do
        it 'renders the raw file' do
          get :show, params: { path: 'user/img/markdown_logo' }, format: :png

          aggregate_failures do
            expect(response).to be_successful
            expect(response.media_type).to eq 'image/png'
            expect(response.headers['Content-Disposition']).to match(/^inline;/)
          end
        end
      end

      context 'when requested file is missing' do
        it 'renders not found' do
          get :show, params: { path: 'foo/bar' }, format: :png
          expect(response).to be_not_found
        end
      end
    end

    context 'for other formats' do
      it 'always renders not found' do
        get :show, params: { path: 'user/ssh' }, format: :foo
        expect(response).to be_not_found
      end
    end

    context 'when requesting an index.md' do
      let(:path) { 'index' }

      subject { get :show, params: { path: path }, format: :md }

      before do
        stub_application_setting(help_page_documentation_base_url: '')
      end

      context 'and the index.md file exists' do
        it 'returns an index.md file' do
          expect(subject).to be_successful
          expect(assigns[:markdown]).to include('Explore the different areas of the documentation')
        end
      end

      context 'but the index.md file does not exist' do
        it 'returns an _index.md file' do
          stub_doc_file_read(content: '_index.md content', file_name: '_index.md')

          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(Rails.root.join('doc/index.md').to_s).and_return(false)
          allow(File).to receive(:exist?).with(Rails.root.join('doc/_index.md').to_s).and_return(true)

          expect(subject).to be_successful
          expect(assigns[:markdown]).to eq '_index.md content'
        end
      end
    end

    context 'when requesting content' do
      subject { get :show, params: { path: 'install/install_methods' }, format: :md }

      before do
        stub_application_setting(help_page_documentation_base_url: '')
        stub_doc_file_read(content: content, file_name: 'install/install_methods.md')
      end

      context 'and the Markdown file has the level 1 heading in frontmatter' do
        let(:content) { "---\ntitle: Test heading\n---\n\nTest content" }

        it 'returns content with the level 1 heading in Markdown' do
          expect(subject).to be_successful
          expect(assigns[:markdown]).to eq "# Test heading\n\nTest content"
        end
      end

      context 'and the Markdown file has the level 1 heading in Markdown' do
        let(:content) { "# Test heading\n\nTest content" }

        it 'returns content with the level 1 heading in Markdown' do
          expect(subject).to be_successful
          expect(assigns[:markdown]).to eq "# Test heading\n\nTest content"
        end
      end
    end
  end

  describe 'GET #docs' do
    subject { get :redirect_to_docs }

    before do
      stub_application_setting(help_page_documentation_base_url: custom_docs_url)
    end

    context 'with no custom docs URL configured' do
      let(:custom_docs_url) { nil }

      it 'redirects to docs.gitlab.com' do
        subject

        expect(response).to redirect_to('https://docs.gitlab.com')
      end
    end

    context 'with a custom docs URL configured' do
      let(:custom_docs_url) { 'https://foo.example.com' }

      it 'redirects to the configured docs URL' do
        subject

        expect(response).to redirect_to(custom_docs_url)
      end
    end
  end

  def stub_two_factor_required
    allow(controller).to receive(:two_factor_authentication_required?).and_return(true)
    allow(controller).to receive(:current_user_requires_two_factor?).and_return(true)
  end
end
