# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContextCommitsFinder do
  describe "#execute" do
    let(:project) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request, source_branch: 'feature', target_branch: 'master') }
    let(:commit) { create(:commit, id: '6d394385cf567f80a8fd85055db1ab4c5295806f') }

    it 'filters commits by valid sha/commit message' do
      params = { search: commit.id }

      commits = described_class.new(project, merge_request, params).execute

      expect(commits.length).to eq(1)
      expect(commits[0].id).to eq(commit.id)
    end

    it 'returns nothing when searched by invalid sha/commit message' do
      params = { search: 'zzz' }

      commits = described_class.new(project, merge_request, params).execute

      expect(commits).to be_empty
    end

    it 'returns commits based in author filter' do
      params = { search: 'test text', author: 'Job van der Voort' }
      commits = described_class.new(project, merge_request, params).execute

      expect(commits.length).to eq(1)
      expect(commits[0].id).to eq('b83d6e391c22777fca1ed3012fce84f633d7fed0')
    end

    it 'returns commits based in before filter' do
      params = { search: 'test text', committed_before: 1474828200 }
      commits = described_class.new(project, merge_request, params).execute

      expect(commits.length).to eq(1)
      expect(commits[0].id).to eq('498214de67004b1da3d820901307bed2a68a8ef6')
    end

    it 'returns commits based in after filter' do
      params = { search: 'test text', committed_after: 1474828200 }
      commits = described_class.new(project, merge_request, params).execute

      expect(commits.length).to eq(1)
      expect(commits[0].id).to eq('b83d6e391c22777fca1ed3012fce84f633d7fed0')
    end
  end
end
