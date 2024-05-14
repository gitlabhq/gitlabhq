# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::TimeTracking::TimelogType, feature_category: :team_planning do
  it { expect(described_class.graphql_name).to eq('WorkItemTimelog') }

  it { expect(described_class).to have_graphql_fields(%w[id spentAt timeSpent user note summary userPermissions]) }
end
