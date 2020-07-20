# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AlertManagementAlertStatusCountsType'] do
  specify { expect(described_class.graphql_name).to eq('AlertManagementAlertStatusCountsType') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      all
      open
      triggered
      acknowledged
      resolved
      ignored
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
