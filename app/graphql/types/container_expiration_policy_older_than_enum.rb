# frozen_string_literal: true

module Types
  class ContainerExpirationPolicyOlderThanEnum < BaseEnum
    OPTIONS_MAPPING = {
      '7d': 'SEVEN_DAYS',
      '14d': 'FOURTEEN_DAYS',
      '30d': 'THIRTY_DAYS',
      '60d': 'SIXTY_DAYS',
      '90d': 'NINETY_DAYS'
    }.freeze

    ::ContainerExpirationPolicy.older_than_options.each do |option, description|
      value OPTIONS_MAPPING[option], description: description, value: option.to_s
    end
  end
end
