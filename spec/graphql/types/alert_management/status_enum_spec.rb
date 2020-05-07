# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['AlertManagementStatus'] do
  specify { expect(described_class.graphql_name).to eq('AlertManagementStatus') }

  it 'exposes all the severity values' do
    expect(described_class.values.keys).to include(*%w[TRIGGERED ACKNOWLEDGED RESOLVED IGNORED])
  end
end
