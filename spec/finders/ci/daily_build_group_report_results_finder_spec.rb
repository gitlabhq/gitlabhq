# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DailyBuildGroupReportResultsFinder do
  describe '#execute' do
    let_it_be(:project) { create(:project, :private) }
    let_it_be(:current_user) { project.owner }
    let_it_be(:ref_path) { 'refs/heads/master' }
    let(:limit) { nil }
    let_it_be(:default_branch) { false }

    let_it_be(:rspec_coverage_1) { create_daily_coverage('rspec', 79.0, '2020-03-09') }
    let_it_be(:karma_coverage_1) { create_daily_coverage('karma', 89.0, '2020-03-09') }
    let_it_be(:rspec_coverage_2) { create_daily_coverage('rspec', 95.0, '2020-03-10') }
    let_it_be(:karma_coverage_2) { create_daily_coverage('karma', 92.0, '2020-03-10') }
    let_it_be(:rspec_coverage_3) { create_daily_coverage('rspec', 97.0, '2020-03-11') }
    let_it_be(:karma_coverage_3) { create_daily_coverage('karma', 99.0, '2020-03-11') }

    let(:attributes) do
      {
        current_user: current_user,
        project: project,
        ref_path: ref_path,
        start_date: '2020-03-09',
        end_date: '2020-03-10',
        limit: limit
      }
    end

    subject(:coverages) do
      described_class.new(**attributes).execute
    end

    context 'when ref_path is present' do
      context 'when current user is allowed to read build report results' do
        it 'returns all matching results within the given date range' do
          expect(coverages).to match_array([
            karma_coverage_2,
            rspec_coverage_2,
            karma_coverage_1,
            rspec_coverage_1
          ])
        end

        context 'and limit is specified' do
          let(:limit) { 2 }

          it 'returns limited number of matching results within the given date range' do
            expect(coverages).to match_array([
              karma_coverage_2,
              rspec_coverage_2
            ])
          end
        end
      end

      context 'when current user is not allowed to read build report results' do
        let(:current_user) { create(:user) }

        it 'returns an empty result' do
          expect(coverages).to be_empty
        end
      end
    end

    context 'when ref_path query parameter is not present' do
      let(:ref_path) { nil }

      context 'when records with cover data from the default branch exist' do
        let(:default_branch) { true }

        it 'returns records with default_branch:true, irrespective of ref_path' do
          rspec_coverage_4 = create_daily_coverage('rspec', 66.0, '2020-03-10')

          expect(coverages).to contain_exactly(rspec_coverage_4)
        end
      end
    end
  end

  private

  def create_daily_coverage(group_name, coverage, date)
    create(
      :ci_daily_build_group_report_result,
      project: project,
      ref_path: ref_path || 'feature-branch',
      group_name: group_name,
      data: { 'coverage' => coverage },
      date: date,
      default_branch: default_branch
    )
  end
end
