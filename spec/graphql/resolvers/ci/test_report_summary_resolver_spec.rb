# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::TestReportSummaryResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :public, :repository) }

    subject(:resolve_subject) { resolve(described_class, obj: pipeline) }

    context 'when pipeline has build report results' do
      let(:pipeline) { create(:ci_pipeline, :with_report_results, project: project) }

      it 'returns test report summary data' do
        expect(resolve_subject.keys).to contain_exactly(:total, :test_suites)
        expect(resolve_subject[:test_suites][0].keys).to contain_exactly(:build_ids, :name, :total_time, :total_count, :success_count, :failed_count, :skipped_count, :error_count, :suite_error)
        expect(resolve_subject[:total][:time]).to eq(0.42)
        expect(resolve_subject[:total][:count]).to eq(2)
        expect(resolve_subject[:total][:success]).to eq(0)
        expect(resolve_subject[:total][:failed]).to eq(0)
        expect(resolve_subject[:total][:skipped]).to eq(0)
        expect(resolve_subject[:total][:error]).to eq(2)
        expect(resolve_subject[:total][:suite_error]).to eq(nil)
      end
    end

    context 'when pipeline does not have build report results' do
      let(:pipeline) { create(:ci_pipeline, project: project) }

      it 'renders test report summary data' do
        expect(resolve_subject.keys).to contain_exactly(:total, :test_suites)
        expect(resolve_subject[:test_suites]).to eq([])
        expect(resolve_subject[:total][:time]).to eq(0)
        expect(resolve_subject[:total][:count]).to eq(0)
        expect(resolve_subject[:total][:success]).to eq(0)
        expect(resolve_subject[:total][:failed]).to eq(0)
        expect(resolve_subject[:total][:skipped]).to eq(0)
        expect(resolve_subject[:total][:error]).to eq(0)
        expect(resolve_subject[:total][:suite_error]).to eq(nil)
      end
    end
  end
end
