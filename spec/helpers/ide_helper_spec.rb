# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IdeHelper, feature_category: :web_ide do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.creator }

  let_it_be(:disabled_vscode_settings) { { enabled: false } }
  let_it_be(:enabled_vscode_settings) do
    { enabled: true,
      vscode_settings: { service_url: 'https://example.com', item_url: 'https://example.com', resource_url_template: 'https://example.com' } }
  end

  before do
    allow(helper).to receive(:current_user).and_return(user)
    allow(helper).to receive(:content_security_policy_nonce).and_return('test-csp-nonce')
    allow(helper).to receive(:new_session_path).and_return('test-sign-in-path')
  end

  describe '#ide_data' do
    let_it_be(:fork_info) { { ide_path: '/test/ide/path' } }
    let_it_be(:params) do
      {
        branch: 'master',
        path: 'foo/bar',
        merge_request_id: '1'
      }
    end

    let(:base_data) do
      {
        'use-new-web-ide' => 'false',
        'user-preferences-path' => profile_preferences_path,
        'sign-in-path' => 'test-sign-in-path',
        'project' => nil,
        'preview-markdown-path' => nil
      }
    end

    it 'returns hash' do
      expect(helper.ide_data(project: nil, fork_info: fork_info, params: params))
        .to include(base_data)
    end

    context 'with project' do
      it 'returns hash with parameters' do
        serialized_project = API::Entities::Project.represent(project, current_user: user).to_json

        expect(
          helper.ide_data(project: project, fork_info: nil, params: params)
        ).to include(base_data.merge(
          'fork-info' => nil,
          'branch-name' => params[:branch],
          'file-path' => params[:path],
          'merge-request' => params[:merge_request_id],
          'project' => serialized_project,
          'preview-markdown-path' => Gitlab::Routing.url_helpers.project_preview_markdown_path(project)
        ))
      end

      context 'with fork info' do
        it 'returns hash with fork info' do
          expect(helper.ide_data(project: project, fork_info: fork_info, params: params))
            .to include('fork-info' => fork_info.to_json)
        end
      end
    end

    context 'with vscode_web_ide=true' do
      let(:base_data) do
        {
          'use-new-web-ide' => 'true',
          'user-preferences-path' => profile_preferences_path,
          'sign-in-path' => 'test-sign-in-path',
          'new-web-ide-help-page-path' =>
            help_page_path('user/project/web_ide/_index.md'),
          'csp-nonce' => 'test-csp-nonce'
        }
      end

      before do
        stub_feature_flags(vscode_web_ide: true)
      end

      it 'returns hash' do
        expect(helper.ide_data(project: nil, fork_info: fork_info, params: params))
          .to include(base_data)
      end

      it 'includes editor font configuration' do
        ide_data = helper.ide_data(project: nil, fork_info: fork_info, params: params)
        editor_font = ::Gitlab::Json.parse(ide_data.fetch('editor-font'), symbolize_names: true)

        expect(editor_font).to include({
          fallback_font_family: 'monospace',
          font_faces: [
            {
              family: 'GitLab Mono',
              display: 'block',
              src: [{
                url: a_string_matching(%r{gitlab-mono/GitLabMono-[^I]}),
                format: 'woff2'
              }]
            },
            {
              family: 'GitLab Mono',
              display: 'block',
              style: 'italic',
              src: [{
                url: a_string_matching(%r{gitlab-mono/GitLabMono-Italic}),
                format: 'woff2'
              }]
            }
          ]
        })
      end

      it 'does not use new web ide if feature flag is disabled' do
        stub_feature_flags(vscode_web_ide: false)

        expect(helper.ide_data(project: nil, fork_info: fork_info, params: params))
          .to include('use-new-web-ide' => 'false')
      end

      context 'for extensions marketplace data' do
        where(:settings, :expected_settings_hash) do
          ref(:disabled_vscode_settings) | nil
          ref(:enabled_vscode_settings) | 'c6620244fe72864fa8d8'
        end

        with_them do
          it 'includes extensions gallery settings and settings context hash' do
            expect(WebIde::ExtensionsMarketplace).to receive(:webide_extensions_gallery_settings)
              .with(user: user).and_return(settings)

            actual = helper.ide_data(project: nil, fork_info: fork_info, params: params)

            expect(actual).to include({
              'extensions-gallery-settings' => settings.to_json,
              'settings-context-hash' => expected_settings_hash
            })
          end
        end
      end

      context 'with project' do
        it 'returns hash with parameters' do
          expect(
            helper.ide_data(project: project, fork_info: nil, params: params)
          ).to include(base_data.merge(
            'branch-name' => params[:branch],
            'file-path' => params[:path],
            'merge-request' => params[:merge_request_id],
            'fork-info' => nil
          ))
        end
      end
    end
  end

  describe '#show_web_ide_oauth_callback_mismatch_callout?' do
    let_it_be(:oauth_application) { create(:oauth_application, owner: nil) }

    before do
      stub_feature_flags(vscode_web_ide: true)
    end

    it 'returns false if no Web IDE OAuth application found' do
      expect(helper.show_web_ide_oauth_callback_mismatch_callout?).to be false
    end

    it "returns true if domain does not match OAuth application callback URLs" do
      stub_application_setting({ web_ide_oauth_application: oauth_application })
      expect(helper.show_web_ide_oauth_callback_mismatch_callout?).to be true
    end

    it "returns false if domain matches OAuth application callback URL" do
      oauth_application.redirect_uri = "#{request.base_url}/oauth-redirect"
      stub_application_setting({ web_ide_oauth_application: oauth_application })
      expect(helper.show_web_ide_oauth_callback_mismatch_callout?).to be false
    end
  end

  describe '#web_ide_oauth_application_id' do
    let_it_be(:oauth_application) { create(:oauth_application, owner: nil) }

    it 'returns Web IDE OAuth application ID' do
      stub_application_setting({ web_ide_oauth_application: oauth_application })
      expect(helper.web_ide_oauth_application_id).to eq(oauth_application.id)
    end
  end
end
