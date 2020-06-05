# frozen_string_literal: true

require 'spec_helper'

describe Ci::DailyBuildGroupReportResultsFinder do
  describe '#execute' do
    let(:project) { create(:project, :private) }
    let(:ref_path) { 'refs/heads/master' }
    let(:limit) { nil }

    let!(:rspec_coverage_1) { create_daily_coverage('rspec', 79.0, '2020-03-09') }
    let!(:karma_coverage_1) { create_daily_coverage('karma', 89.0, '2020-03-09') }
    let!(:rspec_coverage_2) { create_daily_coverage('rspec', 95.0, '2020-03-10') }
    let!(:karma_coverage_2) { create_daily_coverage('karma', 92.0, '2020-03-10') }
    let!(:rspec_coverage_3) { create_daily_coverage('rspec', 97.0, '2020-03-11') }
    let!(:karma_coverage_3) { create_daily_coverage('karma', 99.0, '2020-03-11') }

    subject do
      described_class.new(
        current_user: current_user,
        project: project,
        ref_path: ref_path,
        start_date: '2020-03-09',
        end_date: '2020-03-10',
        limit: limit
      ).execute
    end

    context 'when current user is allowed to read build report results' do
      let(:current_user) { project.owner }

      it 'returns all matching results within the given date range' do
        expect(subject).to match_array([
          karma_coverage_2,
          rspec_coverage_2,
          karma_coverage_1,
          rspec_coverage_1
        ])
      end

      context 'and limit is specified' do
        let(:limit) { 2 }

        it 'returns limited number of matching results within the given date range' do
          expect(subject).to match_array([
            karma_coverage_2,
            rspec_coverage_2
          ])
        end
      end
    end

    context 'when current user is not allowed to read build report results' do
      let(:current_user) { create(:user) }

      it 'returns an empty result' do
        expect(subject).to be_empty
      end
    end
  end

  def create_daily_coverage(group_name, coverage, date)
    create(
      :ci_daily_build_group_report_result,
      project: project,
      ref_path: ref_path,
      group_name: group_name,
      data: { 'coverage' => coverage },
      date: date
    )
  end
end
