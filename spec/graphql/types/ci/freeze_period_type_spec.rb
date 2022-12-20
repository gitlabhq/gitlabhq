# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiFreezePeriod'], feature_category: :release_orchestration do
  specify { expect(described_class.graphql_name).to eq('CiFreezePeriod') }

  it 'has the expected fields' do
    expected_fields = %w[
      status start_cron end_cron cron_timezone start_time end_time
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  specify { expect(described_class).to require_graphql_authorizations(:read_freeze_period) }
end
