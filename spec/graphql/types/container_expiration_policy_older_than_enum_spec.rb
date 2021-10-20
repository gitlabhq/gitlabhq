# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerExpirationPolicyOlderThanEnum'] do
  let_it_be(:expected_values) { %w[SEVEN_DAYS FOURTEEN_DAYS THIRTY_DAYS SIXTY_DAYS NINETY_DAYS] }

  it_behaves_like 'exposing container expiration policy option', :older_than
end
