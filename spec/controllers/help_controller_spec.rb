# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HelpController do
  include StubVersion

  let(:user) { create(:user) }

  shared_examples 'documentation pages local render' do
    it 'renders HTML' do
      aggregate_failures do
        is_expected.to render_template('show.html.haml')
        expect(response.media_type).to eq 'text/html'
      end
    end
  end

  shared_examples 'documentation pages redirect' do |documentation_base_url|
    let(:gitlab_version) { '13.4.0-ee' }

    before do
      stub_version(gitlab_version, 'ignored_revision_value')
    end

    it 'redirects user to custom documentation url with a specified version' do
      is_expected.to redirect_to("#{documentation_base_url}/13.4/ee/#{path}.html")
    end

    context 'when it is a pre-release' do
      let(:gitlab_version) { '13.4.0-pre' }

      it 'redirects user to custom documentation url without a version' do
        is_expected.to redirect_to("#{documentation_base_url}/ee/#{path}.html")
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(help_page_documentation_redirect: false)
      end

      it_behaves_like 'documentation pages local render'
    end
  end

  before do
    sign_in(user)
  end

  describe 'GET #index' do
    context 'with absolute url' do
      it 'keeps the URL absolute' do
        stub_readme("[API](/api/README.md)")

        get :index

        expect(assigns[:help_index]).to eq '[API](/api/README.md)'
      end
    end

    context 'with relative url' do
      it 'prefixes it with /help/' do
        stub_readme("[API](api/README.md)")

        get :index

        expect(assigns[:help_index]).to eq '[API](/help/api/README.md)'
      end
    end

    context 'when url is an external link' do
      it 'does not change it' do
        stub_readme("[external](https://some.external.link)")

        get :index

        expect(assigns[:help_index]).to eq '[external](https://some.external.link)'
      end
    end

    context 'when relative url with external on same line' do
      it 'prefix it with /help/' do
        stub_readme("[API](api/README.md) [external](https://some.external.link)")

        get :index

        expect(assigns[:help_index]).to eq '[API](/help/api/README.md) [external](https://some.external.link)'
      end
    end

    context 'when relative url with http:// in query' do
      it 'prefix it with /help/' do
        stub_readme("[API](api/README.md?go=https://example.com/)")

        get :index

        expect(assigns[:help_index]).to eq '[API](/help/api/README.md?go=https://example.com/)'
      end
    end

    context 'when mailto URL' do
      it 'do not change it' do
        stub_readme("[report bug](mailto:bugs@example.com)")

        get :index

        expect(assigns[:help_index]).to eq '[report bug](mailto:bugs@example.com)'
      end
    end

    context 'when protocol-relative link' do
      it 'do not change it' do
        stub_readme("[protocol-relative](//example.com)")

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
  end

  describe 'GET #show' do
    context 'for Markdown formats' do
      subject { get :show, params: { path: path }, format: :md }

      let(:path) { 'ssh/index' }

      context 'when requested file exists' do
        before do
          expect_file_read(File.join(Rails.root, 'doc/ssh/index.md'), content: fixture_file('blockquote_fence_after.md'))

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

          it_behaves_like 'documentation pages local render'
        end

        context 'when host is missing' do
          let(:host) { nil }

          it_behaves_like 'documentation pages local render'
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
        it 'renders not found' do
          get :show, params: { path: 'foo/bar' }, format: :md
          expect(response).to be_not_found
        end
      end
    end

    context 'for image formats' do
      context 'when requested file exists' do
        it 'renders the raw file' do
          get :show,
              params: {
                path: 'user/img/markdown_logo'
              },
              format: :png

          aggregate_failures do
            expect(response).to be_successful
            expect(response.media_type).to eq 'image/png'
            expect(response.headers['Content-Disposition']).to match(/^inline;/)
          end
        end
      end

      context 'when requested file is missing' do
        it 'renders not found' do
          get :show,
              params: {
                path: 'foo/bar'
              },
              format: :png
          expect(response).to be_not_found
        end
      end
    end

    context 'for other formats' do
      it 'always renders not found' do
        get :show,
            params: {
              path: 'ssh/index'
            },
            format: :foo
        expect(response).to be_not_found
      end
    end
  end

  def stub_readme(content)
    expect_file_read(Rails.root.join('doc', 'README.md'), content: content)
  end

  def stub_two_factor_required
    allow(controller).to receive(:two_factor_authentication_required?).and_return(true)
    allow(controller).to receive(:current_user_requires_two_factor?).and_return(true)
  end
end
