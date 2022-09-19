# frozen_string_literal: true

module Types
  module CustomerRelations
    class ContactSortEnum < SortEnum
      graphql_name 'ContactSort'
      description 'Values for sorting contacts'

      sortable_fields = ['First name', 'Last name', 'Email', 'Phone', 'Description', 'Organization']

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
