# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Repository < Page::Base
          include Common

          view 'app/views/projects/deploy_keys/_index.html.haml' do
            element :deploy_keys_settings
          end

          view 'app/views/projects/protected_branches/shared/_index.html.haml' do
            element :protected_branches_settings
          end

          view 'app/views/projects/mirrors/_mirror_repos.html.haml' do
            element :mirroring_repositories_settings
          end

          def expand_deploy_keys(&block)
            expand_section(:deploy_keys_settings) do
              DeployKeys.perform(&block)
            end
          end

          def expand_protected_branches(&block)
            expand_section(:protected_branches_settings) do
              ProtectedBranches.perform(&block)
            end
          end

          def expand_deploy_tokens(&block)
            expand_section(:deploy_tokens_settings) do
              DeployTokens.perform(&block)
            end
          end

          def expand_mirroring_repositories(&block)
            expand_section(:mirroring_repositories_settings) do
              MirroringRepositories.perform(&block)
            end
          end
        end
      end
    end
  end
end
