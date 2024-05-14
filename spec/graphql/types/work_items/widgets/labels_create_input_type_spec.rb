# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::WorkItems::Widgets::LabelsCreateInputType, feature_category: :team_planning do
  it { expect(described_class.graphql_name).to eq('WorkItemWidgetLabelsCreateInput') }

  it { expect(described_class.arguments.keys).to contain_exactly('labelIds') }
end
