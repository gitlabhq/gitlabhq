# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['UserGroupCalloutFeatureName'], feature_category: :shared do
  specify { expect(described_class.graphql_name).to eq('UserGroupCalloutFeatureName') }

  it 'exposes all the existing user callout feature names' do
    expect(described_class.values.keys).to match_array(::Users::GroupCallout.feature_names.keys.map(&:upcase))
  end
end
