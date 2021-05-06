# frozen_string_literal: true

module Types
  class ContainerExpirationPolicyKeepEnum < BaseEnum
    OPTIONS_MAPPING = {
      1 => 'ONE_TAG',
      5 => 'FIVE_TAGS',
      10 => 'TEN_TAGS',
      25 => 'TWENTY_FIVE_TAGS',
      50 => 'FIFTY_TAGS',
      100 => 'ONE_HUNDRED_TAGS'
    }.freeze

    ::ContainerExpirationPolicy.keep_n_options.each do |option, description|
      value OPTIONS_MAPPING[option], description: description, value: option
    end
  end
end
