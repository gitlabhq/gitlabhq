# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DesignVersion'] do
  it { expect(described_class).to require_graphql_authorizations(:read_design) }

  it 'has the expected fields' do
    expected_fields = %i[id sha designs design_at_version designs_at_version author created_at]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
