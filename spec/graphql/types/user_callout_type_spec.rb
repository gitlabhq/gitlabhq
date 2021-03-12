# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['UserCallout'] do
  specify { expect(described_class.graphql_name).to eq('UserCallout') }

  it 'has expected fields' do
    expect(described_class).to have_graphql_fields(:feature_name, :dismissed_at)
  end
end
