# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DependencyProxyBlob'] do
  it 'includes dependency proxy blob fields' do
    expected_fields = %w[
      file_name size created_at updated_at
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
