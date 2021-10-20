# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Kas::AgentMetadataType do
  include GraphqlHelpers

  let(:fields) { %i[version commit pod_namespace pod_name] }

  it { expect(described_class.graphql_name).to eq('AgentMetadata') }
  it { expect(described_class.description).to eq('Information about a connected Agent') }
  it { expect(described_class).to have_graphql_fields(fields) }
end
