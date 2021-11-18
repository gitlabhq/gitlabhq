# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackageHelmDependencyType'] do
  it { expect(described_class.graphql_name).to eq('PackageHelmDependencyType') }

  it 'includes helm dependency fields' do
    expected_fields = %w[
      name version repository condition tags enabled import_values alias
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
