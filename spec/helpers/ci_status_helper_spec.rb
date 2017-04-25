require 'spec_helper'

describe CiStatusHelper do
  include IconsHelper

  let(:success_commit) { double("Ci::Pipeline", status: 'success') }
  let(:failed_commit) { double("Ci::Pipeline", status: 'failed') }

  describe '#ci_icon_for_status' do
    it 'renders to correct svg on success' do
      expect(helper).to receive(:render)
        .with('shared/icons/icon_status_success.svg', anything)

      helper.ci_icon_for_status(success_commit.status)
    end

    it 'renders the correct svg on failure' do
      expect(helper).to receive(:render)
        .with('shared/icons/icon_status_failed.svg', anything)

      helper.ci_icon_for_status(failed_commit.status)
    end
  end

  describe '#ci_text_for_status' do
    context 'when status is manual' do
      it 'changes the status to blocked' do
        expect(helper.ci_text_for_status('manual'))
          .to eq 'blocked'
      end
    end

    context 'when status is success' do
      it 'changes the status to passed' do
        expect(helper.ci_text_for_status('success'))
          .to eq 'passed'
      end
    end

    context 'when status is something else' do
      it 'returns status unchanged' do
        expect(helper.ci_text_for_status('some-status'))
          .to eq 'some-status'
      end
    end
  end

  describe "#pipeline_status_cache_key" do
    let(:pipeline_status) do
      Gitlab::Cache::Ci::ProjectPipelineStatus
        .new(build(:project), sha: '123abc', status: 'success')
    end

    it "builds a cache key for pipeline status" do
      expect(helper.pipeline_status_cache_key(pipeline_status))
        .to eq("pipeline-status/123abc-success")
    end
  end
end
