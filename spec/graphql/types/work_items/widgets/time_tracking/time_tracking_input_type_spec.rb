# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::TimeTracking::TimeTrackingInputType, feature_category: :team_planning do
  it { expect(described_class.graphql_name).to eq('WorkItemWidgetTimeTrackingInput') }

  it { expect(described_class.arguments.keys).to match_array(%w[timeEstimate timelog]) }
end
