# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::UserPreferencesType do
  specify { expect(described_class.graphql_name).to eq('UserPreferences') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      issues_sort
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
