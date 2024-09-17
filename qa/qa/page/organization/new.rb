# frozen_string_literal: true

module QA
  module Page
    module Organization
      class New < QA::Page::Base
        include QA::Page::Component::Dropdown

        view 'app/assets/javascripts/organizations/shared/components/new_edit_form.vue' do
          element 'organization-name'
          element 'submit-button'
        end

        # Sets the organization name
        # @param name [string] name of organization
        def organization_name=(name)
          fill_element('organization-name', name)
        end

        def create_organization
          click_element('submit-button')
        end
      end
    end
  end
end
