# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::Config::ConfigType do
  specify { expect(described_class.graphql_name).to eq('CiConfig') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      errors
      includes
      mergedYaml
      stages
      status
      warnings
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
