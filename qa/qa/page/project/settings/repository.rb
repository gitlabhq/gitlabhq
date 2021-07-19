# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Repository < Page::Base
          include QA::Page::Settings::Common

          view 'app/views/projects/protected_branches/shared/_index.html.haml' do
            element :protected_branches_settings_content
          end

          view 'app/views/projects/mirrors/_mirror_repos.html.haml' do
            element :mirroring_repositories_settings_content
          end

          view 'app/views/shared/deploy_tokens/_index.html.haml' do
            element :deploy_tokens_settings_content
          end

          view 'app/views/shared/deploy_keys/_index.html.haml' do
            element :deploy_keys_settings_content
          end

          view 'app/views/projects/protected_tags/shared/_index.html.haml' do
            element :protected_tag_settings_content
          end

          def expand_deploy_tokens(&block)
            expand_content(:deploy_tokens_settings_content) do
              Settings::DeployTokens.perform(&block)
            end
          end

          def expand_deploy_keys(&block)
            expand_content(:deploy_keys_settings_content) do
              Settings::DeployKeys.perform(&block)
            end
          end

          def expand_protected_branches(&block)
            expand_content(:protected_branches_settings_content) do
              ProtectedBranches.perform(&block)
            end
          end

          def expand_mirroring_repositories(&block)
            expand_content(:mirroring_repositories_settings_content) do
              MirroringRepositories.perform(&block)
            end
          end

          def expand_protected_tags(&block)
            expand_content(:protected_tag_settings_content) do
              ProtectedTags.perform(&block)
            end
          end

          def expand_default_branch(&block)
            within('#default-branch-settings') do
              find('.btn-default').click do
                DefaultBranch.perform(&block)
              end
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::Repository.prepend_mod_with('Page::Project::Settings::Repository', namespace: QA)
