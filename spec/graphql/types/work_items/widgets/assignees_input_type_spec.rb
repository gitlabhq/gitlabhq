# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::WorkItems::Widgets::AssigneesInputType do
  it { expect(described_class.graphql_name).to eq('WorkItemWidgetAssigneesInput') }

  it { expect(described_class.arguments.keys).to match_array(%w[assigneeIds]) }
end
