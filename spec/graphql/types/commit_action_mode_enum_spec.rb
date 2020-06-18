# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['CommitActionMode'] do
  it { expect(described_class.graphql_name).to eq('CommitActionMode') }

  it 'exposes all the existing commit actions' do
    expect(described_class.values.keys).to match_array(%w[CREATE UPDATE MOVE DELETE CHMOD])
  end
end
