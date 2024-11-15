# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::RelatedBranchType, feature_category: :team_planning do
  it { expect(described_class.graphql_name).to eq('WorkItemRelatedBranch') }

  it { expect(described_class).to have_graphql_fields(:name, :compare_path, :pipeline_status) }
end
