# frozen_string_literal: true

module Types
  class ContainerExpirationPolicyCadenceEnum < BaseEnum
    OPTIONS_MAPPING = {
      '1d': 'EVERY_DAY',
      '7d': 'EVERY_WEEK',
      '14d': 'EVERY_TWO_WEEKS',
      '1month': 'EVERY_MONTH',
      '3month': 'EVERY_THREE_MONTHS'
    }.freeze

    ::ContainerExpirationPolicy.cadence_options.each do |option, description|
      value OPTIONS_MAPPING[option], description: description, value: option.to_s
    end
  end
end
