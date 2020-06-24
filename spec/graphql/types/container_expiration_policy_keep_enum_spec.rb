# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerExpirationPolicyKeepEnum'] do
  let_it_be(:expected_values) { %w[ONE_TAG FIVE_TAGS TEN_TAGS TWENTY_FIVE_TAGS FIFTY_TAGS ONE_HUNDRED_TAGS] }

  it_behaves_like 'exposing container expiration policy option', :keep_n
end
