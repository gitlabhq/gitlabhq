# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiGroupVariableConnection'] do
  it 'has the expected fields' do
    expected_fields = %i[limit page_info edges nodes]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
