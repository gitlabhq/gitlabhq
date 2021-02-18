# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequest::MetricsFinder do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request_not_merged) { create(:merge_request, :unique_branches, source_project: project) }
  let_it_be(:merged_at) { Time.new(2020, 5, 1) }
  let_it_be(:merge_request_merged) do
    create(:merge_request, :unique_branches, :merged, source_project: project).tap do |mr|
      mr.metrics.update!(merged_at: merged_at)
    end
  end

  let(:params) do
    {
      target_project: project,
      merged_after: merged_at - 10.days,
      merged_before: merged_at + 10.days
    }
  end

  subject { described_class.new(current_user, params).execute.to_a }

  context 'when target project is missing' do
    before do
      params.delete(:target_project)
    end

    it { is_expected.to be_empty }
  end

  context 'when the user is not part of the project' do
    it { is_expected.to be_empty }
  end

  context 'when user is part of the project' do
    before do
      project.add_developer(current_user)
    end

    it 'returns merge request records' do
      is_expected.to eq([merge_request_merged.metrics])
    end

    it 'excludes not merged records' do
      is_expected.not_to eq([merge_request_not_merged.metrics])
    end

    context 'when only merged_before is given' do
      before do
        params.delete(:merged_after)
      end

      it { is_expected.to eq([merge_request_merged.metrics]) }
    end

    context 'when only merged_after is given' do
      before do
        params.delete(:merged_before)
      end

      it { is_expected.to eq([merge_request_merged.metrics]) }
    end

    context 'when no records matching the date range' do
      before do
        params[:merged_before] = merged_at - 1.year
        params[:merged_after] = merged_at - 2.years
      end

      it { is_expected.to be_empty }
    end
  end
end
