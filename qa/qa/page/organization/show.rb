# frozen_string_literal: true

module QA
  module Page
    module Organization
      class Show < QA::Page::Base
        include QA::Page::Component::Dropdown

        view 'app/assets/javascripts/organizations/show/components/organization_avatar.vue' do
          element 'organization-name'
        end

        def has_organization?(name)
          has_element?('organization-name', text: name)
        end
      end
    end
  end
end
