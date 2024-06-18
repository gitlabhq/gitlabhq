# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DependencyProxyImageTtlGroupPolicy'], feature_category: :virtual_registry do
  it { expect(described_class.graphql_name).to eq('DependencyProxyImageTtlGroupPolicy') }

  it { expect(described_class.description).to eq('Group-level Dependency Proxy TTL policy settings') }

  it { expect(described_class).to require_graphql_authorizations(:admin_dependency_proxy) }

  it 'includes dependency proxy image ttl policy fields' do
    expected_fields = %w[enabled ttl created_at updated_at]

    expect(described_class).to have_graphql_fields(*expected_fields).only
  end
end
