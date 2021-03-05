# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['UserCalloutFeatureNameEnum'] do
  specify { expect(described_class.graphql_name).to eq('UserCalloutFeatureNameEnum') }

  it 'exposes all the existing user callout feature names' do
    expect(described_class.values.keys).to match_array(::UserCallout.feature_names.keys.map(&:upcase))
  end
end
