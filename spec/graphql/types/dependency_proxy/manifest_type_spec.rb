# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DependencyProxyManifest'] do
  it 'includes dependency proxy manifest fields' do
    expected_fields = %w[
      id file_name image_name size created_at updated_at digest status
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
