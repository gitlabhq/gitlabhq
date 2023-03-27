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
      params = { author: 'Job van der Voort' }
      commits = described_class.new(project, merge_request, params).execute

      expect(commits.length).to eq(1)
      expect(commits[0].id).to eq('b83d6e391c22777fca1ed3012fce84f633d7fed0')
    end

    it 'returns commits based in committed before and after filter' do
      params = { committed_before: 1471631400, committed_after: 1471458600 } # August 18, 2016 - # August 20, 2016
      commits = described_class.new(project, merge_request, params).execute

      expect(commits.length).to eq(2)
      expect(commits[0].id).to eq('1b12f15a11fc6e62177bef08f47bc7b5ce50b141')
      expect(commits[1].id).to eq('38008cb17ce1466d8fec2dfa6f6ab8dcfe5cf49e')
    end

    it 'returns commits from target branch if no filter is applied' do
      expect(project.repository).to receive(:commits).with(merge_request.target_branch, anything).and_call_original

      commits = described_class.new(project, merge_request).execute

      expect(commits.length).to eq(37)
      expect(commits[0].id).to eq('b83d6e391c22777fca1ed3012fce84f633d7fed0')
      expect(commits[1].id).to eq('498214de67004b1da3d820901307bed2a68a8ef6')
    end
  end
end
