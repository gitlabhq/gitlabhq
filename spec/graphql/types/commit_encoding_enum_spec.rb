# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CommitEncoding'] do
  it { expect(described_class.graphql_name).to eq('CommitEncoding') }

  it 'exposes all the existing encoding option' do
    expect(described_class.values.keys).to match_array(%w[TEXT BASE64])
  end
end
