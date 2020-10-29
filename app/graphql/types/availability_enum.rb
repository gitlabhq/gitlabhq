# frozen_string_literal: true

module Types
  class AvailabilityEnum < BaseEnum
    graphql_name 'AvailabilityEnum'
    description 'User availability status'

    ::UserStatus.availabilities.keys.each do |availability_value|
      value availability_value.upcase, value: availability_value, description: availability_value.titleize
    end
  end
end
