# frozen_string_literal: true

module Types
  module Users
    class FirstDayOfWeekEnum < BaseEnum
      graphql_name 'UserFirstDayOfWeek'
      description 'First day of the week in calendars and date pickers.'

      value 'SUNDAY', value: ::UserPreference::FIRST_DAYS_OF_WEEK[:sunday], description: 'Sunday.'
      value 'MONDAY', value: ::UserPreference::FIRST_DAYS_OF_WEEK[:monday], description: 'Monday.'
      value 'SATURDAY', value: ::UserPreference::FIRST_DAYS_OF_WEEK[:saturday], description: 'Saturday.'
    end
  end
end
