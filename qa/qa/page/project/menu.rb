# frozen_string_literal: true

module QA
  module Page
    module Project
      class Menu < Page::Base
        include SubMenus::Common
        include SubMenus::Repository

        view 'app/views/layouts/nav/sidebar/_project.html.haml' do
          element :settings_item
          element :settings_link, 'link_to edit_project_path' # rubocop:disable QA/ElementWithPattern
          element :link_pipelines
          element :link_members_settings
          element :pipelines_settings_link, "title: _('CI / CD')" # rubocop:disable QA/ElementWithPattern
          element :operations_kubernetes_link, "title: _('Kubernetes')" # rubocop:disable QA/ElementWithPattern
          element :operations_environments_link
          element :issues_link, /link_to.*shortcuts-issues/ # rubocop:disable QA/ElementWithPattern
          element :issues_link_text, "Issues" # rubocop:disable QA/ElementWithPattern
          element :merge_requests_link, /link_to.*shortcuts-merge_requests/ # rubocop:disable QA/ElementWithPattern
          element :merge_requests_link_text, "Merge Requests" # rubocop:disable QA/ElementWithPattern
          element :top_level_items, '.sidebar-top-level-items' # rubocop:disable QA/ElementWithPattern
          element :operations_section, "class: 'shortcuts-operations'" # rubocop:disable QA/ElementWithPattern
          element :activity_link, "title: _('Activity')" # rubocop:disable QA/ElementWithPattern
          element :wiki_link_text, "Wiki" # rubocop:disable QA/ElementWithPattern
          element :milestones_link
          element :labels_link
        end

        view 'app/assets/javascripts/fly_out_nav.js' do
          element :fly_out, "classList.add('fly-out-list')" # rubocop:disable QA/ElementWithPattern
        end

        def click_ci_cd_pipelines
          within_sidebar do
            click_element :link_pipelines
          end
        end

        def click_ci_cd_settings
          hover_settings do
            within_submenu do
              click_link('CI / CD')
            end
          end
        end

        def click_issues
          within_sidebar do
            click_link('Issues')
          end
        end

        def click_members_settings
          hover_settings do
            within_submenu do
              click_element :link_members_settings
            end
          end
        end

        def click_merge_requests
          within_sidebar do
            click_link('Merge Requests')
          end
        end

        def click_operations_environments
          hover_operations do
            within_submenu do
              click_element(:operations_environments_link)
            end
          end
        end

        def click_operations_kubernetes
          hover_operations do
            within_submenu do
              click_link('Kubernetes')
            end
          end
        end

        def click_milestones
          within_sidebar do
            click_element :milestones_link
          end
        end

        def click_repository_settings
          hover_settings do
            within_submenu do
              click_link('Repository')
            end
          end
        end

        def click_wiki
          within_sidebar do
            click_link('Wiki')
          end
        end

        def go_to_activity
          within_sidebar do
            click_on 'Activity'
          end
        end

        def go_to_labels
          hover_issues do
            within_submenu do
              click_element(:labels_link)
            end
          end
        end

        def go_to_settings
          within_sidebar do
            click_on 'Settings'
          end
        end

        private

        def hover_issues
          within_sidebar do
            find_element(:issues_item).hover

            yield
          end
        end

        def hover_operations
          within_sidebar do
            find('.shortcuts-operations').hover

            yield
          end
        end

        def hover_settings
          within_sidebar do
            find('.qa-settings-item').hover

            yield
          end
        end
      end
    end
  end
end
