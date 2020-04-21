# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['BoardList'] do
  it { expect(described_class.graphql_name).to eq('BoardList') }

  it 'has specific fields' do
    expected_fields = %w[id list_type position label]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
