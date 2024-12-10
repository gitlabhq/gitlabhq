# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Kas::AgentWarningType, feature_category: :deployment_management do
  include GraphqlHelpers

  let(:fields) { %i[version] }

  it { expect(described_class.graphql_name).to eq('AgentWarning') }
  it { expect(described_class.description).to eq('Warning object for a connected Agent') }
  it { expect(described_class).to have_graphql_fields(fields) }
end
