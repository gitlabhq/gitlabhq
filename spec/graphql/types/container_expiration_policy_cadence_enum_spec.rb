# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerExpirationPolicyCadenceEnum'] do
  let_it_be(:expected_values) { %w[EVERY_DAY EVERY_WEEK EVERY_TWO_WEEKS EVERY_MONTH EVERY_THREE_MONTHS] }

  it_behaves_like 'exposing container expiration policy option', :cadence
end
