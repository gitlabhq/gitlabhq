# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::OldestPerCommitFinder do
  describe '#execute' do
    it 'returns a Hash mapping commit SHAs to their oldest merge requests' do
      project = create(:project)
      mr1 = create(:merge_request, :merged, target_project: project)
      mr2 = create(:merge_request, :merged, target_project: project)
      mr1_diff = create(:merge_request_diff, merge_request: mr1)
      mr2_diff = create(:merge_request_diff, merge_request: mr2)
      sha1 = Digest::SHA1.hexdigest('foo')
      sha2 = Digest::SHA1.hexdigest('bar')

      create(:merge_request_diff_commit, merge_request_diff: mr1_diff, sha: sha1)
      create(:merge_request_diff_commit, merge_request_diff: mr2_diff, sha: sha1)
      create(
        :merge_request_diff_commit,
        merge_request_diff: mr2_diff,
        sha: sha2,
        relative_order: 1
      )

      commits = [double(:commit, id: sha1), double(:commit, id: sha2)]

      expect(described_class.new(project).execute(commits)).to eq(
        sha1 => mr1,
        sha2 => mr2
      )
    end

    it 'skips merge requests that are not merged' do
      mr = create(:merge_request)
      mr_diff = create(:merge_request_diff, merge_request: mr)
      sha = Digest::SHA1.hexdigest('foo')

      create(:merge_request_diff_commit, merge_request_diff: mr_diff, sha: sha)

      commits = [double(:commit, id: sha)]

      expect(described_class.new(mr.target_project).execute(commits))
        .to be_empty
    end
  end
end
