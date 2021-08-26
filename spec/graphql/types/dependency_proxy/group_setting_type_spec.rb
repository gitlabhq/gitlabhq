# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DependencyProxySetting'] do
  it 'includes dependency proxy blob fields' do
    expected_fields = %w[
      enabled
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
