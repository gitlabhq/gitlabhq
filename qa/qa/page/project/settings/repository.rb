# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Repository < Page::Base
          include QA::Page::Settings::Common

          view 'app/views/protected_branches/shared/_index.html.haml' do
            element 'protected-branches-settings-content'
          end

          view 'app/views/projects/mirrors/_mirror_repos.html.haml' do
            element 'mirroring-repositories-settings-content'
          end

          view 'app/views/shared/deploy_tokens/_index.html.haml' do
            element 'deploy-tokens-settings-content'
          end

          view 'app/views/shared/deploy_keys/_index.html.haml' do
            element 'deploy-keys-settings-content'
          end

          view 'app/views/projects/protected_tags/shared/_index.html.haml' do
            element 'protected-tag-settings-content'
          end

          view 'app/views/projects/branch_rules/_show.html.haml' do
            element 'branch-rules-content'
          end

          def expand_deploy_tokens(&block)
            expand_content('deploy-tokens-settings-content') do
              Settings::ProjectDeployTokens.perform(&block)
            end
          end

          def expand_deploy_keys(&block)
            expand_content('deploy-keys-settings-content') do
              Settings::DeployKeys.perform(&block)
            end
          end

          def expand_protected_branches(&block)
            expand_content('protected-branches-settings-content') do
              ProtectedBranches.perform(&block)
            end
          end

          def expand_mirroring_repositories(&block)
            expand_content('mirroring-repositories-settings-content') do
              MirroringRepositories.perform(&block)
            end
          end

          def expand_protected_tags(&block)
            expand_content('protected-tag-settings-content') do
              ProtectedTags.perform(&block)
            end
          end

          def expand_branch_rules
            expand_content('branch-rules-content')
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::Repository.prepend_mod_with('Page::Project::Settings::Repository', namespace: QA)
