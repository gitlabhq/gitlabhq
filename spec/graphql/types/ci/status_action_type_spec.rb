# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::StatusActionType do
  specify { expect(described_class.graphql_name).to eq('StatusAction') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      buttonTitle
      icon
      path
      method
      title
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
