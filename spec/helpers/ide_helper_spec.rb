# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IdeHelper, feature_category: :web_ide do
  describe '#ide_data' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { project.creator }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:content_security_policy_nonce).and_return('test-csp-nonce')
    end

    context 'with vscode_web_ide=true and instance vars set' do
      before do
        stub_feature_flags(vscode_web_ide: true)
      end

      it 'returns hash' do
        expect(
          helper.ide_data(
            project: project,
            branch: 'master',
            path: 'foo/README.md',
            merge_request: '7',
            fork_info: nil,
            learn_gitlab_source: nil
          )
        ).to match(
          'can-use-new-web-ide' => 'true',
          'use-new-web-ide' => 'true',
          'user-preferences-path' => profile_preferences_path,
          'new-web-ide-help-page-path' =>
            help_page_path('user/project/web_ide/index.md', anchor: 'vscode-reimplementation'),
          'branch-name' => 'master',
          'project-path' => project.path_with_namespace,
          'csp-nonce' => 'test-csp-nonce',
          'ide-remote-path' => ide_remote_path(remote_host: ':remote_host', remote_path: ':remote_path'),
          'file-path' => 'foo/README.md',
          'editor-font-family' => 'JetBrains Mono',
          'editor-font-format' => 'woff2',
          'editor-font-src-url' => a_string_matching(%r{jetbrains-mono/JetBrainsMono}),
          'merge-request' => '7',
          'fork-info' => nil,
          'learn-gitlab-source' => 'false'
        )
      end

      it 'does not use new web ide if user.use_legacy_web_ide' do
        allow(user).to receive(:use_legacy_web_ide).and_return(true)

        expect(
          helper.ide_data(
            project: project,
            branch: nil,
            path: nil,
            merge_request: nil,
            fork_info: nil,
            learn_gitlab_source: nil
          )
        ).to include('use-new-web-ide' => 'false')
      end

      it 'returns source data in the hash if learn gitlab source' do
        allow(user).to receive(:use_legacy_web_ide).and_return(true)

        expect(
          helper.ide_data(
            project: project,
            branch: nil,
            path: nil,
            merge_request: nil,
            fork_info: nil,
            learn_gitlab_source: true
          )
        ).to include('learn-gitlab-source' => 'true')
      end
    end

    context 'with vscode_web_ide=false' do
      before do
        stub_feature_flags(vscode_web_ide: false)
      end

      context 'when instance vars and parameters are not set' do
        it 'returns instance data in the hash as nil' do
          expect(
            helper.ide_data(
              project: nil,
              branch: nil,
              path: nil,
              merge_request: nil,
              fork_info: nil,
              learn_gitlab_source: nil
            )
          ).to include(
            'can-use-new-web-ide' => 'false',
            'use-new-web-ide' => 'false',
            'user-preferences-path' => profile_preferences_path,
            'branch-name' => nil,
            'file-path' => nil,
            'merge-request' => nil,
            'fork-info' => nil,
            'project' => nil,
            'preview-markdown-path' => nil
          )
        end
      end

      context 'when instance vars are set' do
        it 'returns instance data in the hash' do
          fork_info = { ide_path: '/test/ide/path' }

          serialized_project = API::Entities::Project.represent(project, current_user: project.creator).to_json

          expect(
            helper.ide_data(
              project: project,
              branch: 'master',
              path: 'foo/bar',
              merge_request: '1',
              fork_info: fork_info,
              learn_gitlab_source: nil
            )
          ).to include(
            'branch-name' => 'master',
            'file-path' => 'foo/bar',
            'merge-request' => '1',
            'fork-info' => fork_info.to_json,
            'project' => serialized_project,
            'preview-markdown-path' => Gitlab::Routing.url_helpers.preview_markdown_project_path(project)
          )
        end
      end

      context 'environments guidance experiment', :experiment do
        before do
          stub_experiments(in_product_guidance_environments_webide: :candidate)
        end

        context 'when project has no enviornments' do
          it 'enables environment guidance' do
            expect(
              helper.ide_data(
                project: project,
                branch: nil,
                path: nil,
                merge_request: nil,
                fork_info: nil,
                learn_gitlab_source: nil
              )
            ).to include('enable-environments-guidance' => 'true')
          end

          context 'and the callout has been dismissed' do
            it 'disables environment guidance' do
              callout = create(:callout, feature_name: :web_ide_ci_environments_guidance, user: project.creator)
              callout.update!(dismissed_at: Time.now - 1.week)
              allow(helper).to receive(:current_user).and_return(User.find(project.creator.id))

              expect(
                helper.ide_data(
                  project: project,
                  branch: nil,
                  path: nil,
                  merge_request: nil,
                  fork_info: nil,
                  learn_gitlab_source: nil
                )
              ).to include('enable-environments-guidance' => 'false')
            end
          end
        end

        context 'when the project has environments' do
          it 'disables environment guidance' do
            create(:environment, project: project)

            expect(
              helper.ide_data(
                project: project,
                branch: nil,
                path: nil,
                merge_request: nil,
                fork_info: nil,
                learn_gitlab_source: nil
              )
            ).to include('enable-environments-guidance' => 'false')
          end
        end
      end
    end
  end
end
