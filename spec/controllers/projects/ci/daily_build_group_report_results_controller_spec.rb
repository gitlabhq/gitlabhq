# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Ci::DailyBuildGroupReportResultsController do
  describe 'GET index' do
    let(:project) { create(:project, :public, :repository) }
    let(:ref_path) { 'refs/heads/master' }
    let(:param_type) { 'coverage' }
    let(:start_date) { '2019-12-10' }
    let(:end_date) { '2020-03-09' }
    let(:allowed_to_read) { true }
    let(:user) { create(:user) }

    before do
      create_daily_coverage('rspec', 79.0, '2020-03-09')
      create_daily_coverage('rspec', 77.0, '2020-03-08')
      create_daily_coverage('karma', 81.0, '2019-12-10')
      create_daily_coverage('minitest', 67.0, '2019-12-09')
      create_daily_coverage('mocha', 71.0, '2019-12-09')

      sign_in(user)

      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?).with(user, :read_build_report_results, project).and_return(allowed_to_read)

      get :index, params: {
        namespace_id: project.namespace,
        project_id: project,
        ref_path: ref_path,
        param_type: param_type,
        start_date: start_date,
        end_date: end_date,
        format: format
      }
    end

    shared_examples_for 'validating param_type' do
      context 'when given param_type is invalid' do
        let(:param_type) { 'something_else' }

        it 'responds with 422 error' do
          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end
    end

    shared_examples_for 'ensuring policy' do
      context 'when user is not allowed to read build report results' do
        let(:allowed_to_read) { false }

        it 'responds with 404 error' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when format is CSV' do
      let(:format) { :csv }

      it 'serves the results in CSV' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Content-Type']).to eq('text/csv; charset=utf-8')

        expect(csv_response).to eq([
          %w[date group_name coverage],
          ['2020-03-09', 'rspec', '79.0'],
          ['2020-03-08', 'rspec', '77.0'],
          ['2019-12-10', 'karma', '81.0']
        ])
      end

      context 'when given date range spans more than 90 days' do
        let(:start_date) { '2019-12-09' }
        let(:end_date) { '2020-03-09' }

        it 'limits the result to 90 days from the given start_date' do
          expect(csv_response).to eq([
            %w[date group_name coverage],
            ['2020-03-09', 'rspec', '79.0'],
            ['2020-03-08', 'rspec', '77.0'],
            ['2019-12-10', 'karma', '81.0']
          ])
        end
      end

      it_behaves_like 'validating param_type'
      it_behaves_like 'ensuring policy'
    end

    context 'when format is JSON' do
      let(:format) { :json }

      it 'serves the results in JSON' do
        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response).to eq([
          {
            'group_name' => 'rspec',
            'data' => [
              { 'date' => '2020-03-09', 'coverage' => 79.0 },
              { 'date' => '2020-03-08', 'coverage' => 77.0 }
            ]
          },
          {
            'group_name' => 'karma',
            'data' => [
              { 'date' => '2019-12-10', 'coverage' => 81.0 }
            ]
          }
        ])
      end

      context 'when given date range spans more than 90 days' do
        let(:start_date) { '2019-12-09' }
        let(:end_date) { '2020-03-09' }

        it 'limits the result to 90 days from the given start_date' do
          expect(json_response).to eq([
            {
              'group_name' => 'rspec',
              'data' => [
                { 'date' => '2020-03-09', 'coverage' => 79.0 },
                { 'date' => '2020-03-08', 'coverage' => 77.0 }
              ]
            },
            {
              'group_name' => 'karma',
              'data' => [
                { 'date' => '2019-12-10', 'coverage' => 81.0 }
              ]
            }
          ])
        end
      end

      it_behaves_like 'validating param_type'
      it_behaves_like 'ensuring policy'
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
