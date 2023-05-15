# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ProjectStatisticsRedirect'], feature_category: :consumables_cost_management do
  it 'has all the required fields' do
    expect(described_class).to have_graphql_fields(:repository, :build_artifacts, :packages,
      :wiki, :snippets, :container_registry)
  end
end
