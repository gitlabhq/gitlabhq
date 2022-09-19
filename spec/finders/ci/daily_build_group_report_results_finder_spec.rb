# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DailyBuildGroupReportResultsFinder do
  describe '#execute' do
    let_it_be(:project) { create(:project, :private) }
    let(:user_without_permission) { create(:user) }
    let_it_be(:user_with_permission) { project.first_owner }
    let_it_be(:ref_path) { 'refs/heads/master' }
    let(:limit) { nil }
    let_it_be(:default_branch) { false }
    let(:start_date) { '2020-03-09' }
    let(:end_date) { '2020-03-10' }
    let(:sort) { true }

    let_it_be(:rspec_coverage_1) { create_daily_coverage('rspec', 79.0, '2020-03-09') }
    let_it_be(:karma_coverage_1) { create_daily_coverage('karma', 89.0, '2020-03-09') }
    let_it_be(:rspec_coverage_2) { create_daily_coverage('rspec', 95.0, '2020-03-10') }
    let_it_be(:karma_coverage_2) { create_daily_coverage('karma', 92.0, '2020-03-10') }
    let_it_be(:rspec_coverage_3) { create_daily_coverage('rspec', 97.0, '2020-03-11') }
    let_it_be(:karma_coverage_3) { create_daily_coverage('karma', 99.0, '2020-03-11') }

    let(:finder) { described_class.new(params: params, current_user: current_user) }

    let(:params) do
      {
        project: project,
        coverage: true,
        ref_path: ref_path,
        start_date: start_date,
        end_date: end_date,
        limit: limit,
        sort: sort
      }
    end

    subject(:coverages) { finder.execute }

    context 'when params are provided' do
      context 'when current user is not allowed to read data' do
        let(:current_user) { user_without_permission }

        it 'returns an empty collection' do
          expect(coverages).to be_empty
        end
      end

      context 'when current user is allowed to read data' do
        let(:current_user) { user_with_permission }

        it 'returns matching coverages within the given date range' do
          expect(coverages).to match_array(
            [
              karma_coverage_2,
              rspec_coverage_2,
              karma_coverage_1,
              rspec_coverage_1
            ])
        end

        context 'when ref_path is nil' do
          let(:default_branch) { true }
          let(:ref_path) { nil }

          it 'returns coverages for the default branch' do
            rspec_coverage_4 = create_daily_coverage('rspec', 66.0, '2020-03-10')

            expect(coverages).to contain_exactly(rspec_coverage_4)
          end
        end

        context 'when limit is specified' do
          let(:limit) { 2 }

          it 'returns limited number of matching coverages within the given date range' do
            expect(coverages).to match_array(
              [
                karma_coverage_2,
                rspec_coverage_2
              ])
          end
        end

        context 'when provided dates are nil' do
          let(:start_date) { nil }
          let(:end_date) { nil }
          let(:rspec_coverage_4) { create_daily_coverage('rspec', 98.0, 91.days.ago.to_date.to_s) }

          it 'returns all coverages from the last 90 days' do
            expect(coverages).to match_array(
              [
                karma_coverage_3,
                rspec_coverage_3,
                karma_coverage_2,
                rspec_coverage_2,
                karma_coverage_1,
                rspec_coverage_1
              ]
            )
          end
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
