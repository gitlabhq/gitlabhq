# frozen_string_literal: true

module Types
  module Organizations
    class GroupSortEnum < BaseEnum
      graphql_name 'OrganizationGroupSort'
      description 'Values for sorting organization groups'

      sortable_fields = ['ID', 'Name', 'Path', 'Updated at', 'Created at']

      sortable_fields.each do |field|
        value "#{field.upcase.tr(' ', '_')}_ASC",
          value: { field: field.downcase.tr(' ', '_'), direction: :asc },
          description: "#{field} in ascending order.",
          alpha: { milestone: '16.4' }

        value "#{field.upcase.tr(' ', '_')}_DESC",
          value: { field: field.downcase.tr(' ', '_'), direction: :desc },
          description: "#{field} in descending order.",
          alpha: { milestone: '16.4' }
      end
    end
  end
end
