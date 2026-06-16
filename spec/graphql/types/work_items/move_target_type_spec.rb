# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::MoveTargetType, feature_category: :team_planning do
  let(:fields) { %i[source_type suggested_target_type valid_target_types] }

  specify { expect(described_class.graphql_name).to eq('WorkItemMoveTarget') }
  specify { expect(described_class).to have_graphql_fields(fields) }
end
