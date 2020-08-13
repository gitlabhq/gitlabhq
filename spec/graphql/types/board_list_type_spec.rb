# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['BoardList'] do
  specify { expect(described_class.graphql_name).to eq('BoardList') }

  it 'has specific fields' do
    expected_fields = %w[id list_type position label issues_count issues]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
