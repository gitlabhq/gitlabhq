# frozen_string_literal: true

module Types
  module TimeTracking
    class TimelogSortEnum < SortEnum
      graphql_name 'TimelogSort'
      description 'Values for sorting timelogs'

      sortable_fields = ['Spent at', 'Time spent']

      sortable_fields.each do |field|
        value "#{field.upcase.tr(' ', '_')}_ASC",
          value: { field: field.downcase.tr(' ', '_'), direction: :asc },
          description: "#{field} by ascending order."
        value "#{field.upcase.tr(' ', '_')}_DESC",
          value: { field: field.downcase.tr(' ', '_'), direction: :desc },
          description: "#{field} by descending order."
      end
    end
  end
end
