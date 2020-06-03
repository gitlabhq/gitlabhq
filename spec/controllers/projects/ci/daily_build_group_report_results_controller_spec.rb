# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Ci::DailyBuildGroupReportResultsController do
  describe 'GET index' do
    let(:project) { create(:project, :public, :repository) }
    let(:ref_path) { 'refs/heads/master' }
    let(:param_type) { 'coverage' }
    let(:start_date) { '2019-12-10' }
    let(:end_date) { '2020-03-09' }

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

    def csv_response
      CSV.parse(response.body)
    end

    before do
      create_daily_coverage('rspec', 79.0, '2020-03-09')
      create_daily_coverage('karma', 81.0, '2019-12-10')
      create_daily_coverage('rspec', 67.0, '2019-12-09')
      create_daily_coverage('karma', 71.0, '2019-12-09')

      get :index, params: {
        namespace_id: project.namespace,
        project_id: project,
        ref_path: ref_path,
        param_type: param_type,
        start_date: start_date,
        end_date: end_date,
        format: :csv
      }
    end

    it 'serves the results in CSV' do
      expect(response).to have_gitlab_http_status(:ok)
      expect(response.headers['Content-Type']).to eq('text/csv; charset=utf-8')

      expect(csv_response).to eq([
        %w[date group_name coverage],
        ['2020-03-09', 'rspec', '79.0'],
        ['2019-12-10', 'karma', '81.0']
      ])
    end

    context 'when given date range spans more than 90 days' do
      let(:start_date) { '2019-12-09' }
      let(:end_date) { '2020-03-09' }

      it 'limits the result to 90 days from the given start_date' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Content-Type']).to eq('text/csv; charset=utf-8')

        expect(csv_response).to eq([
          %w[date group_name coverage],
          ['2020-03-09', 'rspec', '79.0'],
          ['2019-12-10', 'karma', '81.0']
        ])
      end
    end

    context 'when given param_type is invalid' do
      let(:param_type) { 'something_else' }

      it 'responds with 422 error' do
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end
  end
end
