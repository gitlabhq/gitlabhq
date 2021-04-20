# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::OldestPerCommitFinder do
  describe '#execute' do
    it 'returns a Hash mapping commit SHAs to their oldest merge requests' do
      project = create(:project)
      sha1 = Digest::SHA1.hexdigest('foo')
      sha2 = Digest::SHA1.hexdigest('bar')
      sha3 = Digest::SHA1.hexdigest('baz')
      mr1 = create(:merge_request, :merged, target_project: project)
      mr2 = create(:merge_request, :merged, target_project: project)
      mr3 = create(
        :merge_request,
        :merged,
        target_project: project,
        merge_commit_sha: sha3
      )

      mr1_diff = create(:merge_request_diff, merge_request: mr1)
      mr2_diff = create(:merge_request_diff, merge_request: mr2)

      create(:merge_request_diff_commit, merge_request_diff: mr1_diff, sha: sha1)
      create(:merge_request_diff_commit, merge_request_diff: mr2_diff, sha: sha1)
      create(
        :merge_request_diff_commit,
        merge_request_diff: mr2_diff,
        sha: sha2,
        relative_order: 1
      )

      commits = [
        double(:commit, id: sha1),
        double(:commit, id: sha2),
        double(:commit, id: sha3)
      ]

      expect(described_class.new(project).execute(commits)).to eq(
        sha1 => mr1,
        sha2 => mr2,
        sha3 => mr3
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

    it 'includes the merge request for a merge commit' do
      project = create(:project)
      sha = Digest::SHA1.hexdigest('foo')
      mr = create(
        :merge_request,
        :merged,
        target_project: project,
        merge_commit_sha: sha
      )

      commits = [double(:commit, id: sha)]

      # This expectation is set so we're certain that the merge commit SHAs (if
      # a matching merge request is found) aren't also used for finding MRs
      # according to diffs.
      expect(MergeRequestDiffCommit)
        .not_to receive(:oldest_merge_request_id_per_commit)

      expect(described_class.new(project).execute(commits)).to eq(sha => mr)
    end

    it 'includes a merge request that was squashed into the target branch' do
      project = create(:project)
      sha = Digest::SHA1.hexdigest('foo')
      mr = create(
        :merge_request,
        :merged,
        target_project: project,
        squash_commit_sha: sha
      )

      commits = [double(:commit, id: sha)]

      expect(MergeRequestDiffCommit)
        .not_to receive(:oldest_merge_request_id_per_commit)

      expect(described_class.new(project).execute(commits)).to eq(sha => mr)
    end

    it 'includes a merge request for both a squash and merge commit' do
      project = create(:project)
      sha1 = Digest::SHA1.hexdigest('foo')
      sha2 = Digest::SHA1.hexdigest('bar')
      mr = create(
        :merge_request,
        :merged,
        target_project: project,
        squash_commit_sha: sha1,
        merge_commit_sha: sha2
      )

      commits = [double(:commit1, id: sha1), double(:commit2, id: sha2)]

      expect(MergeRequestDiffCommit)
        .not_to receive(:oldest_merge_request_id_per_commit)

      expect(described_class.new(project).execute(commits))
        .to eq(sha1 => mr, sha2 => mr)
    end

    it 'includes the oldest merge request when a merge commit is present in a newer merge request' do
      project = create(:project)
      sha = Digest::SHA1.hexdigest('foo')
      mr1 = create(
        :merge_request,
        :merged,
        target_project: project, merge_commit_sha: sha
      )

      mr2 = create(:merge_request, :merged, target_project: project)
      mr_diff = create(:merge_request_diff, merge_request: mr2)

      create(:merge_request_diff_commit, merge_request_diff: mr_diff, sha: sha)

      commits = [double(:commit, id: sha)]

      expect(described_class.new(project).execute(commits)).to eq(sha => mr1)
    end
  end
end
