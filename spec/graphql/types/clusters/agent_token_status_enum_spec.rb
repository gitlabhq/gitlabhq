# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Clusters::AgentTokenStatusEnum do
  it { expect(described_class.graphql_name).to eq('AgentTokenStatus') }
  it { expect(described_class.values.keys).to match_array(Clusters::AgentToken.statuses.keys.map(&:upcase)) }
end
