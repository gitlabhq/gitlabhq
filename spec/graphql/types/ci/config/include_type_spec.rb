# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::Config::IncludeType do
  specify { expect(described_class.graphql_name).to eq('CiConfigInclude') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      context_project
      context_sha
      extra
      location
      blob
      raw
      type
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
