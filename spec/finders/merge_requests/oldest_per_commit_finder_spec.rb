# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::OldestPerCommitFinder, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project) }

  describe '#execute' do
    shared_examples 'finder for oldest MR per commit' do |with_metadata: false|
      it 'returns a Hash mapping commit SHAs to their oldest merge requests' do
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

        create_commit(mr1_diff, sha1, create_metadata: with_metadata)
        create_commit(mr2_diff, sha1, create_metadata: with_metadata)
        create_commit(mr2_diff, sha2, position: 1, create_metadata: with_metadata)

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
        mr = create(:merge_request, target_project: project, source_project: project)
        mr_diff = create(:merge_request_diff, merge_request: mr)
        sha = Digest::SHA1.hexdigest('foo')

        create_commit(mr_diff, sha, create_metadata: with_metadata)

        commits = [double(:commit, id: sha)]

        expect(described_class.new(mr.target_project).execute(commits))
          .to be_empty
      end

      it 'includes the merge request for a merge commit' do
        sha = Digest::SHA1.hexdigest('foo')
        mr = create(
          :merge_request,
          :merged,
          target_project: project,
          merge_commit_sha: sha
        )

        commits = [double(:commit, id: sha)]

        # These expectations are set so we're certain that the merge commit SHAs (if
        # a matching merge request is found) aren't also used for finding MRs
        # according to diffs.
        expect(MergeRequestDiffCommit)
          .not_to receive(:oldest_merge_request_id_per_commit)

        expect(MergeRequest::CommitsMetadata)
          .not_to receive(:oldest_merge_request_id_per_commit)

        expect(described_class.new(project).execute(commits)).to eq(sha => mr)
      end

      it 'includes a merge request that was squashed into the target branch' do
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

        expect(MergeRequest::CommitsMetadata)
          .not_to receive(:oldest_merge_request_id_per_commit)

        expect(described_class.new(project).execute(commits)).to eq(sha => mr)
      end

      it 'includes a merge request for both a squash and merge commit' do
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

        expect(MergeRequest::CommitsMetadata)
          .not_to receive(:oldest_merge_request_id_per_commit)

        expect(described_class.new(project).execute(commits))
          .to eq(sha1 => mr, sha2 => mr)
      end

      it 'includes a merge request for fast-forward merged MR' do
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

        expect(MergeRequest::CommitsMetadata)
          .not_to receive(:oldest_merge_request_id_per_commit)

        expect(described_class.new(project).execute(commits))
          .to eq(sha => mr)
      end

      it 'includes the oldest merge request when a merge commit is present in a newer merge request' do
        sha = Digest::SHA1.hexdigest('foo')
        mr1 = create(
          :merge_request,
          :merged,
          target_project: project, merge_commit_sha: sha
        )

        mr2 = create(:merge_request, :merged, target_project: project)
        create_commit(mr2.merge_request_diff, sha, create_metadata: with_metadata)

        commits = [double(:commit, id: sha)]

        expect(described_class.new(project).execute(commits)).to eq(sha => mr1)
      end
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

    context 'when SHAs are only present in `merge_request_diff_commits` table' do
      it_behaves_like 'finder for oldest MR per commit'

      context 'when feature flag merge_request_diff_commits_dedup is disabled' do
        before do
          stub_feature_flags(merge_request_diff_commits_dedup: false)
        end

        it_behaves_like 'finder for oldest MR per commit'
      end
    end

    context 'when SHAs are only present in `merge_request_commits_metadata` table' do
      it_behaves_like 'finder for oldest MR per commit', with_metadata: true

      context 'when feature flag merge_request_diff_commits_dedup is disabled' do
        before do
          stub_feature_flags(merge_request_diff_commits_dedup: false)
        end

        it 'reverts to query `merge_request_diff_commits` table' do
          sha = Digest::SHA1.hexdigest('foo')
          mr1 = create(:merge_request, :merged, target_project: project)
          create_commit(mr1.merge_request_diff, sha, create_metadata: true)

          commits = [double(:commit, id: sha)]

          expect(MergeRequest::CommitsMetadata)
            .not_to receive(:oldest_merge_request_id_per_commit)
          expect(described_class.new(project).execute(commits)).to be_empty
        end
      end
    end

    context 'when SHAs are present in both tables' do
      it 'returns a Hash mapping commit SHAs to their oldest merge requests' do
        sha1 = Digest::SHA1.hexdigest('foo')
        sha2 = Digest::SHA1.hexdigest('bar')
        sha3 = Digest::SHA1.hexdigest('baz')
        mr1 = create(:merge_request, :merged, target_project: project)
        mr2 = create(:merge_request, :merged, target_project: project)
        mr3 = create(:merge_request, :merged, target_project: project, merge_commit_sha: sha3)

        mr1_diff = mr1.merge_request_diff
        mr2_diff = mr2.merge_request_diff

        create_commit(mr1_diff, sha1, create_metadata: true)
        create_commit(mr2_diff, sha1, create_metadata: true)
        create_commit(mr2_diff, sha2, position: 1, create_metadata: false)

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
    end
  end

  def create_commit(diff, sha, position: 0, create_metadata: false)
    metadata =
      if create_metadata
        MergeRequest::CommitsMetadata.find_by(sha: sha, project: project) ||
          create(:merge_request_commits_metadata, sha: sha, project: project)
      end

    sha_value = create_metadata ? nil : sha

    create(
      :merge_request_diff_commit,
      merge_request_diff: diff,
      sha: sha_value,
      relative_order: position,
      merge_request_commits_metadata_id: metadata&.id
    )
  end
end
