# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['UserContributionCalendar'], feature_category: :user_profile do
  specify { expect(described_class.graphql_name).to eq('UserContributionCalendar') }

  it 'exposes the expected fields' do
    expect(described_class).to have_graphql_fields(:utc_offset, :timezone, :days, :total_count)
  end
end
