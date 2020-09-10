# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['InstanceStatisticsMeasurement'] do
  subject { described_class }

  it { is_expected.to have_graphql_field(:recorded_at) }
  it { is_expected.to have_graphql_field(:identifier) }
  it { is_expected.to have_graphql_field(:count) }
end
