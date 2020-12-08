# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProjectPipelineStatisticsResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }

  specify do
    expect(described_class).to have_nullable_graphql_type(::Types::Ci::AnalyticsType)
  end

  def resolve_statistics(project, args)
    resolve(described_class, obj: project, args: args)
  end

  describe '#resolve' do
    it 'returns the pipelines statistics for a given project' do
      result = resolve_statistics(project, {})
      expect(result.keys).to contain_exactly(
        :week_pipelines_labels,
        :week_pipelines_totals,
        :week_pipelines_successful,
        :month_pipelines_labels,
        :month_pipelines_totals,
        :month_pipelines_successful,
        :year_pipelines_labels,
        :year_pipelines_totals,
        :year_pipelines_successful,
        :pipeline_times_labels,
        :pipeline_times_values
      )
    end
  end
end
