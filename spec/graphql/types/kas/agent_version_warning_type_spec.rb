# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Kas::AgentVersionWarningType, feature_category: :deployment_management do
  include GraphqlHelpers

  let(:fields) { %i[message type] }

  it { expect(described_class.graphql_name).to eq('AgentVersionWarning') }
  it { expect(described_class.description).to eq('Version-related warning for a connected Agent') }
  it { expect(described_class).to have_graphql_fields(fields) }
end
