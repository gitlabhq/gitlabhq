# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ClusterAgentAuthorizationCiAccess'],
  feature_category: :deployment_management do
  let(:fields) { %i[agent config] }

  it { expect(described_class.graphql_name).to eq('ClusterAgentAuthorizationCiAccess') }
  it { expect(described_class).to have_graphql_fields(fields) }
end
