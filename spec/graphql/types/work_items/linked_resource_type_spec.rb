# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::LinkedResourceType, feature_category: :team_planning do
  it { expect(described_class.graphql_name).to eq('WorkItemLinkedResource') }

  it { expect(described_class).to have_graphql_fields(:url) }
end
