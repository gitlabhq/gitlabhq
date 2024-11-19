# frozen_string_literal: true

module Types
  module Organizations
    class GroupsProjectsDisplayEnum < BaseEnum
      graphql_name 'OrganizationGroupProjectDisplay'
      description 'Default list view for organization groups and projects.'

      UserPreference.organization_groups_projects_displays.each_key do |field|
        value field.upcase, value: field,
          description: "Display organization #{field} list.",
          experiment: { milestone: '17.2' }
      end
    end
  end
end
