# frozen_string_literal: true
require 'spec_helper'

RSpec.describe GitlabSchema.types['AccessLevel'] do
  specify { expect(described_class.graphql_name).to eq('AccessLevel') }
  specify { expect(described_class).to require_graphql_authorizations(nil) }

  it 'has expected fields' do
    expected_fields = [:integer_value, :string_value, :human_access]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
