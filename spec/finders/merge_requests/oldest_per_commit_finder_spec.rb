# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::OldestPerCommitFinder, feature_category: :code_review_workflow do
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

      mr1_diff = mr1.merge_request_diff
      mr2_diff = mr2.merge_request_diff

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
      #
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

    it 'includes a merge request for fast-forward merged MR' do
      project = create(:project)
      sha = Digest::SHA1.hexdigest('foo')
      # When there is only a merged_commit_sha, then it means the MR was
      # fast-forward merged without a squash, but possibly including a rebase.
      mr = create(
        :merge_request,
        :merged,
        target_project: project,
        merged_commit_sha: sha
      )

      commits = [double(:commit1, id: sha)]

      expect(MergeRequestDiffCommit)
        .not_to receive(:oldest_merge_request_id_per_commit)

      expect(described_class.new(project).execute(commits))
        .to eq(sha => mr)
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

      create(
        :merge_request_diff_commit,
        merge_request_diff: mr2.merge_request_diff,
        sha: sha
      )

      commits = [double(:commit, id: sha)]

      expect(described_class.new(project).execute(commits)).to eq(sha => mr1)
    end

    it 'includes the merge request for a commit coming from a generated ref commit' do
      project = create(:project)
      sha = Digest::SHA1.hexdigest('foo')
      mr = create(
        :merge_request,
        :merged,
        target_project: project,
        merge_commit_sha: sha
      )

      create(:merge_request_generated_ref_commit, project: project, merge_request: mr)

      commits = [instance_double(Commit, id: MergeRequests::GeneratedRefCommit.first.commit_sha)]

      expect(described_class.new(project).execute(commits)).to eq(
        MergeRequests::GeneratedRefCommit.first.commit_sha => mr
      )
    end

    context 'when feature include_generated_ref_commits_in_changelog is disabled' do
      before do
        stub_feature_flags(include_generated_ref_commits_in_changelog: false)
      end

      it 'does not include the merge request for a commit coming from a generated ref commit' do
        project = create(:project)
        sha = Digest::SHA1.hexdigest('foo')
        mr = create(
          :merge_request,
          :merged,
          target_project: project,
          merge_commit_sha: sha
        )

        create(:merge_request_generated_ref_commit, project: project, merge_request: mr)

        commits = [instance_double(Commit, id: MergeRequests::GeneratedRefCommit.first.commit_sha)]

        expect(described_class.new(project).execute(commits)).to be_empty
      end
    end
  end
end
