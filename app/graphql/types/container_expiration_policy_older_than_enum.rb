# frozen_string_literal: true

module Types
  class ContainerExpirationPolicyOlderThanEnum < BaseEnum
    OPTIONS_MAPPING = {
      '1d': 'ONE_DAY',
      '3d': 'THREE_DAYS',
      '7d': 'SEVEN_DAYS',
      '14d': 'FOURTEEN_DAYS',
      '30d': 'THIRTY_DAYS',
      '60d': 'SIXTY_DAYS',
      '90d': 'NINETY_DAYS',
      '180d': 'ONE_HUNDRED_EIGHTY_DAYS',
      '365d': 'THREE_HUNDRED_SIXTY_FIVE_DAYS',
      '730d': 'SEVEN_HUNDRED_THIRTY_DAYS',
      '1095d': 'ONE_THOUSAND_NINETY_FIVE_DAYS'
    }.freeze

    ::ContainerExpirationPolicy.older_than_options.each do |option, description|
      value OPTIONS_MAPPING[option], description: description, value: option.to_s
    end
  end
end
