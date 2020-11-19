# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::UserStatusType do
  specify { expect(described_class.graphql_name).to eq('UserStatus') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      emoji
      message
      message_html
      availability
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
