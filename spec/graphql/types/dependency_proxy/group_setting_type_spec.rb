# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DependencyProxySetting'] do
  it 'includes dependency proxy blob fields' do
    expected_fields = %w[
      enabled
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  it { expect(described_class).to require_graphql_authorizations(:admin_dependency_proxy) }

  it { expect(described_class.graphql_name).to eq('DependencyProxySetting') }

  it { expect(described_class.description).to eq('Group-level Dependency Proxy settings') }
end
