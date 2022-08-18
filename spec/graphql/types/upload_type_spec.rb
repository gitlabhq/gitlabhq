# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['FileUpload'] do
  it { expect(described_class).to require_graphql_authorizations(:read_upload) }

  it 'has the expected fields' do
    expected_fields = %w[id size path]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
