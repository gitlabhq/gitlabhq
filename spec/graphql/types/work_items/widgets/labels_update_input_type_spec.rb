# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::WorkItems::Widgets::LabelsUpdateInputType do
  it { expect(described_class.graphql_name).to eq('WorkItemWidgetLabelsUpdateInput') }

  it { expect(described_class.arguments.keys).to contain_exactly('addLabelIds', 'removeLabelIds') }
end
