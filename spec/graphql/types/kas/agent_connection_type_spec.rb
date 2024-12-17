# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Kas::AgentConnectionType do
  include GraphqlHelpers

  let(:fields) { %i[connected_at connection_id metadata warnings] }

  it { expect(described_class.graphql_name).to eq('ConnectedAgent') }
  it { expect(described_class.description).to eq('Connection details for an Agent') }
  it { expect(described_class).to have_graphql_fields(fields) }

  describe '#connected_at' do
    let(:connected_at) { double(Google::Protobuf::Timestamp, seconds: 123456, nanos: 654321) }
    let(:object) { double(Gitlab::Agent::AgentTracker::Rpc::ConnectedAgent, connected_at: connected_at) }

    it 'converts the seconds value to a timestamp' do
      expect(resolve_field(:connected_at, object)).to eq(Time.at(connected_at.seconds))
    end
  end
end
