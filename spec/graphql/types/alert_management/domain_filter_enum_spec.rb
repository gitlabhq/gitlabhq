# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AlertManagementDomainFilter'] do
  specify { expect(described_class.graphql_name).to eq('AlertManagementDomainFilter') }

  it 'exposes all the severity values' do
    expect(described_class.values.keys).to include(*%w[operations threat_monitoring])
  end
end
