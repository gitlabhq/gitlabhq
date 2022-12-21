# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TimelogSort'], feature_category: :team_planning do
  specify { expect(described_class.graphql_name).to eq('TimelogSort') }

  it_behaves_like 'common sort values'

  it 'exposes all the contact sort values' do
    expect(described_class.values.keys).to include(
      *%w[
        SPENT_AT_ASC
        SPENT_AT_DESC
        TIME_SPENT_ASC
        TIME_SPENT_DESC
      ]
    )
  end
end
