# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiConfigIncludeType'] do
  it { expect(described_class.graphql_name).to eq('CiConfigIncludeType') }

  it 'exposes all the existing include types' do
    expect(described_class.values.keys).to match_array(%w[remote local file template component])
  end
end
