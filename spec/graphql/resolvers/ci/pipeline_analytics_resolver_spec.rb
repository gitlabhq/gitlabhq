# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::PipelineAnalyticsResolver, :click_house, feature_category: :fleet_visibility do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:public_project) { create(:project, :public) }
  let_it_be(:project) { create(:project, :private, group: group) }
  let_it_be(:guest) { create(:user, guest_of: [project, public_project, group]) }
  let_it_be(:reporter) { create(:user, reporter_of: [project, public_project, group]) }

  let(:current_user) { reporter }
  let(:lookahead) { positive_lookahead }

  before do
    allow(lookahead).to receive(:arguments).and_return({ period: :day })
  end

  specify do
    expect(described_class).to have_nullable_graphql_type(::Types::Ci::AnalyticsType)
  end

  specify do
    expect(described_class.extras).to include(:lookahead)
  end

  shared_examples 'returns the pipeline analytics for a given container' do
    it 'loads all fields' do
      expected_fields = [:aggregate, :time_series]
      expected_fields.concat(legacy_fields)

      result = resolve_statistics(container, {})
      expect(result.keys).to match_array(expected_fields)
    end

    context 'with negative lookahead' do
      let(:lookahead) { negative_lookahead }

      it 'does not load fields that execute queries' do
        result = resolve_statistics(container, {})
        expect(result.keys).to be_empty
      end
    end
  end

  shared_examples 'it returns nils' do
    it do # # rubocop:disable RSpec/ExampleWithoutDescription -- Shared examples title is self explanatory
      result = resolve_statistics(project, {})

      expect(result).to be_nil
    end
  end

  def resolve_statistics(container, args)
    ctx = { current_user: current_user }

    resolve(described_class, obj: container, args: args, ctx: ctx, lookahead: lookahead, arg_style: :internal)
  end

  describe '#resolve' do
    context 'when container is a project' do
      let_it_be(:container) { project }

      let(:legacy_fields) do
        [
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
        ]
      end

      it_behaves_like 'returns the pipeline analytics for a given container'

      context 'when the user does not have access to the CI/CD analytics data' do
        let(:current_user) { guest }

        it_behaves_like 'it returns nils'
      end

      context 'when the project is public' do
        let(:container) { public_project }

        context 'when public pipelines are disabled' do
          before do
            project.update!(public_builds: false)
          end

          context 'when user is not a member' do
            let(:current_user) { create(:user) }

            it_behaves_like 'it returns nils'
          end

          context 'when user is a guest' do
            let(:current_user) { guest }

            it_behaves_like 'it returns nils'
          end

          context 'when user is a reporter or above' do
            let(:current_user) { reporter }

            it_behaves_like 'returns the pipeline analytics for a given container'
          end
        end

        context 'when public pipelines are enabled' do
          before do
            project.update!(public_builds: true)
          end

          context 'when user is not a member' do
            let(:current_user) { create(:user) }

            it_behaves_like 'returns the pipeline analytics for a given container'
          end
        end
      end
    end

    context 'when container is a group' do
      let_it_be(:container) { group }

      let(:legacy_fields) { [] } # Legacy fields are not exposed for groups

      it_behaves_like 'returns the pipeline analytics for a given container'
    end
  end
end
