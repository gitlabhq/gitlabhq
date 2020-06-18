# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContextCommitsFinder do
  describe "#execute" do
    let(:project) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request) }
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
  end
end
