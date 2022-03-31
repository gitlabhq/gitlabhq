# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProjectPipelineStatisticsResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }

  let(:current_user) { reporter }

  before do
    project.add_guest(guest)
    project.add_reporter(reporter)
  end

  specify do
    expect(described_class).to have_nullable_graphql_type(::Types::Ci::AnalyticsType)
  end

  shared_examples 'returns the pipelines statistics for a given project' do
    it do
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

  shared_examples 'it returns nils' do
    it do
      result = resolve_statistics(project, {})

      expect(result).to be_nil
    end
  end

  def resolve_statistics(project, args)
    ctx = { current_user: current_user }
    resolve(described_class, obj: project, args: args, ctx: ctx)
  end

  describe '#resolve' do
    it_behaves_like 'returns the pipelines statistics for a given project'

    context 'when the user does not have access to the CI/CD analytics data' do
      let(:current_user) { guest }

      it_behaves_like 'it returns nils'
    end

    context 'when the project is public' do
      let_it_be(:project) { create(:project, :public) }

      context 'public pipelines are disabled' do
        before do
          project.update!(public_builds: false)
        end

        context 'user is not a member' do
          let(:current_user) { create(:user) }

          it_behaves_like 'it returns nils'
        end

        context 'user is a guest' do
          let(:current_user) { guest }

          it_behaves_like 'it returns nils'
        end

        context 'user is a reporter or above' do
          let(:current_user) { reporter }

          it_behaves_like 'returns the pipelines statistics for a given project'
        end
      end

      context 'public pipelines are enabled' do
        before do
          project.update!(public_builds: true)
        end

        context 'user is not a member' do
          let(:current_user) { create(:user) }

          it_behaves_like 'returns the pipelines statistics for a given project'
        end
      end
    end
  end
end
