# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['AlertManagementSeverity'] do
  it { expect(described_class.graphql_name).to eq('AlertManagementSeverity') }

  it 'exposes all the severity values' do
    expect(described_class.values.keys).to include(*%w[CRITICAL HIGH MEDIUM LOW INFO UNKNOWN])
  end
end
