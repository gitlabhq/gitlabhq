# frozen_string_literal: true

module QA
  module Page
    module Group
      class New < Page::Base
        include Page::Component::VisibilitySetting

        view 'app/assets/javascripts/groups/components/group_name_and_path.vue' do
          element 'group-path-field'
          element 'group-name-field'
        end

        view 'app/views/groups/_new_group_fields.html.haml' do
          element 'create-group-button'
        end

        view 'app/views/groups/_import_group_from_another_instance_panel.html.haml' do
          element 'import-gitlab-url'
          element 'import-gitlab-token'
          element 'connect-instance-button'
        end

        view 'app/assets/javascripts/vue_shared/new_namespace/components/welcome.vue' do
          element 'panel-link'
        end

        def set_path(path)
          fill_element('group-path-field', path)
          fill_element('group-name-field', path)
        end

        def create
          click_element('create-group-button')
        end

        def create_subgroup
          click_button 'Create subgroup'
        end

        def set_gitlab_url(url)
          fill_element('import-gitlab-url', url)
        end

        def set_gitlab_token(token)
          fill_element('import-gitlab-token', token)
        end

        def click_import_group
          click_on 'Import group'
        end

        def click_create_group
          click_element('panel-link', panel_name: 'create-group-pane')
        end

        # Connect gitlab instance
        #
        # @param [String] gitlab_url
        # @param [String] gitlab_token
        # @return [void]
        def connect_gitlab_instance(gitlab_url, gitlab_token)
          # Wait until element is present and refresh if not in case feature flag did not kick in
          wait_until(max_duration: 10) { has_element?('import-gitlab-url', wait: 1) }

          set_gitlab_url(gitlab_url)
          set_gitlab_token(gitlab_token)

          click_element('connect-instance-button')
        end

        def switch_to_import_tab
          click_element('panel-link', panel_name: 'import-group-pane')
        end
      end
    end
  end
end
