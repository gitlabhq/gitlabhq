# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MergeRequestDiffComparison, feature_category: :integrations do
  include RepoHelpers
  let(:diff_with_commits) { create(:merge_request).merge_request_diff }

  subject(:merge_request_diff_instance) { described_class.new(diff_with_commits) }

  describe '#compare_with' do
    it 'delegates compare_with to the service' do
      expect(CompareService).to receive(:new).and_call_original

      described_class
        .new(diff_with_commits)
        .compare_with(nil)
    end

    it 'uses git diff A..B approach by default' do
      diffs = described_class
                .new(diff_with_commits)
                .compare_with('0b4bc9a49b562e85de7cc9e834518ea6828729b9')
                .diffs

      expect(diffs.size).to eq(21)
    end
  end
end
