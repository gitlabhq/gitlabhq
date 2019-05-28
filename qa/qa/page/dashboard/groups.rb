# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      class Groups < Page::Base
        include Page::Component::GroupsFilter

        view 'app/views/shared/groups/_search_form.html.haml' do
          element :groups_filter, 'search_field_tag :filter' # rubocop:disable QA/ElementWithPattern
          element :groups_filter_placeholder, 'Search by name' # rubocop:disable QA/ElementWithPattern
        end

        view 'app/views/dashboard/_groups_head.html.haml' do
          element :new_group_button, 'link_to _("New group")' # rubocop:disable QA/ElementWithPattern
        end

        def has_group?(name)
          has_filtered_group?(name)
        end

        def click_group(name)
          raise "Group with name #{name} not found!" unless has_group?(name)

          click_link name
        end

        def click_new_group
          click_on 'New group'
        end
      end
    end
  end
end
