# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerExpirationPolicyOlderThanEnum'] do
  let_it_be(:expected_values) do
    %w[
      ONE_DAY
      THREE_DAYS
      SEVEN_DAYS
      FOURTEEN_DAYS
      THIRTY_DAYS
      SIXTY_DAYS
      NINETY_DAYS
      ONE_HUNDRED_EIGHTY_DAYS
      THREE_HUNDRED_SIXTY_FIVE_DAYS
      SEVEN_HUNDRED_THIRTY_DAYS
      ONE_THOUSAND_NINETY_FIVE_DAYS
    ]
  end

  it_behaves_like 'exposing container expiration policy option', :older_than
end
