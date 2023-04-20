# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::WorkItems::Widgets::CurrentUserTodosInputType, feature_category: :team_planning do
  it { expect(described_class.graphql_name).to eq('WorkItemWidgetCurrentUserTodosInput') }

  it { expect(described_class.arguments.keys).to match_array(%w[action todoId]) }
end
