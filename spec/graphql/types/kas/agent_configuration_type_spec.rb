# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AgentConfiguration'] do
  let(:fields) { %i[agent_name] }

  it { expect(described_class.graphql_name).to eq('AgentConfiguration') }
  it { expect(described_class.description).to eq('Configuration details for an Agent') }
  it { expect(described_class).to have_graphql_fields(fields) }
end
