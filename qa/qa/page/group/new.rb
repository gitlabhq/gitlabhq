# frozen_string_literal: true

module QA
  module Page
    module Group
      class New < Page::Base
        include Page::Component::VisibilitySetting

        view 'app/views/shared/_group_form.html.haml' do
          element :group_path_field
          element :group_name_field
        end

        view 'app/views/groups/_new_group_fields.html.haml' do
          element :create_group_button, "submit _('Create group')" # rubocop:disable QA/ElementWithPattern
        end

        view 'app/views/groups/_import_group_from_another_instance_panel.html.haml' do
          element :import_gitlab_url
          element :import_gitlab_token
          element :connect_instance_button
        end

        def set_path(path)
          fill_element(:group_path_field, path)
          fill_element(:group_name_field, path)
        end

        def create
          click_button 'Create group'
        end

        def set_gitlab_url(url)
          fill_element(:import_gitlab_url, url)
        end

        def set_gitlab_token(token)
          fill_element(:import_gitlab_token, token)
        end

        # Connect gitlab instance
        #
        # @param [String] gitlab_url
        # @param [String] gitlab_token
        # @return [void]
        def connect_gitlab_instance(gitlab_url, gitlab_token)
          set_gitlab_url(gitlab_url)
          set_gitlab_token(gitlab_token)

          click_element(:connect_instance_button)
        end
      end
    end
  end
end
