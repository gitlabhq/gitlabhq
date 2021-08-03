# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProjectPipelineStatisticsResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }

  let(:current_user) { reporter }

  before_all do
    project.add_guest(guest)
    project.add_reporter(reporter)
  end

  specify do
    expect(described_class).to have_nullable_graphql_type(::Types::Ci::AnalyticsType)
  end

  def resolve_statistics(project, args)
    ctx = { current_user: current_user }
    resolve(described_class, obj: project, args: args, ctx: ctx)
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

    context 'when the user does not have access to the CI/CD analytics data' do
      let(:current_user) { guest }

      it 'returns nil' do
        result = resolve_statistics(project, {})

        expect(result).to be_nil
      end
    end
  end
end
