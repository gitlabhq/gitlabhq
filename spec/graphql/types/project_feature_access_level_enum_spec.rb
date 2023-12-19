# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ProjectFeatureAccessLevel'], feature_category: :groups_and_projects do
  specify { expect(described_class.graphql_name).to eq('ProjectFeatureAccessLevel') }

  it 'exposes all the existing access levels' do
    expect(described_class.values.keys).to include(*%w[DISABLED PRIVATE ENABLED])
  end
end
