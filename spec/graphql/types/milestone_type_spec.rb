# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Milestone'] do
  specify { expect(described_class.graphql_name).to eq('Milestone') }

  specify { expect(described_class).to require_graphql_authorizations(:read_milestone) }

  it 'has the expected fields' do
    expected_fields = %w[
      id iid title description state expired web_path
      due_date start_date created_at updated_at
      project_milestone group_milestone subgroup_milestone
      stats
    ]

    expect(described_class).to have_graphql_fields(*expected_fields).at_least
  end

  describe 'stats field' do
    subject { described_class.fields['stats'] }

    it { is_expected.to have_graphql_type(Types::MilestoneStatsType) }
  end
end
