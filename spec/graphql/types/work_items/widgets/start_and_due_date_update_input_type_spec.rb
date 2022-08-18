# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::WorkItems::Widgets::StartAndDueDateUpdateInputType do
  it { expect(described_class.graphql_name).to eq('WorkItemWidgetStartAndDueDateUpdateInput') }

  it { expect(described_class.arguments.keys).to contain_exactly('startDate', 'dueDate') }
end
