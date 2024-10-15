# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::WorkItems::Widgets::StartAndDueDateUpdateInputType, feature_category: :team_planning do
  specify do
    expect(described_class.graphql_name).to eq('WorkItemWidgetStartAndDueDateUpdateInput')
  end

  context 'when on FOSS', unless: Gitlab.ee? do
    specify { expect(described_class.arguments.keys).to contain_exactly('startDate', 'dueDate') }
  end
end
