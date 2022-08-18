# frozen_string_literal: true

module Types
  module CustomerRelations
    class OrganizationSortEnum < SortEnum
      graphql_name 'OrganizationSort'
      description 'Values for sorting organizations'

      sortable_fields = ['Name', 'Description', 'Default Rate']

      sortable_fields.each do |field|
        value "#{field.upcase.tr(' ', '_')}_ASC",
          value: { field: field.downcase.tr(' ', '_'), direction: :asc },
          description: "#{field} in ascending order."
        value "#{field.upcase.tr(' ', '_')}_DESC",
          value: { field: field.downcase.tr(' ', '_'), direction: :desc },
          description: "#{field} in descending order."
      end
    end
  end
end
