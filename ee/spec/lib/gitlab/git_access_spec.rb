require 'spec_helper'

describe Gitlab::GitAccess do
  set(:user) { create(:user) }

  let(:actor) { user }
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:protocol) { 'web' }
  let(:authentication_abilities) { %i[read_project download_code push_code] }
  let(:redirected_path) { nil }

  let(:access) { described_class.new(actor, project, protocol, authentication_abilities: authentication_abilities, redirected_path: redirected_path) }

  context "when in a read-only GitLab instance" do
    before do
      create(:protected_branch, name: 'feature', project: project)
      allow(Gitlab::Database).to receive(:read_only?) { true }
    end

    let(:primary_repo_url) { "https://localhost:3000/gitlab/#{project.full_path}.git" }

    it_behaves_like 'a read-only GitLab instance'
  end

  describe "push_rule_check" do
    let(:start_sha) { '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9' }
    let(:end_sha)   { '570e7b2abdd848b95f2f578043fc23bd6f6fd24d' }
    let(:changes)   { "#{start_sha} #{end_sha} refs/heads/master" }

    before do
      project.add_developer(user)

      allow(project.repository).to receive(:new_commits)
        .and_return(project.repository.commits_between(start_sha, end_sha))
    end

    describe "author email check" do
      it 'returns true' do
        expect { push_changes(changes) }.not_to raise_error
      end

      it 'returns false when a commit message is missing required matches (positive regex match)' do
        project.create_push_rule(commit_message_regex: "@only.com")

        expect { push_changes(changes) }.to raise_error(described_class::UnauthorizedError)
      end

      it 'returns false when a commit message contains forbidden characters (negative regex match)' do
        project.create_push_rule(commit_message_negative_regex: "@gmail.com")

        expect { push_changes(changes) }.to raise_error(described_class::UnauthorizedError)
      end

      it 'returns true for tags' do
        project.create_push_rule(commit_message_regex: "@only.com")

        expect { push_changes("#{start_sha} #{end_sha} refs/tags/v1") }.not_to raise_error
      end

      it 'allows githook for new branch with an old bad commit' do
        bad_commit = double("Commit", safe_message: 'Some change').as_null_object
        ref_object = double(name: 'heads/master')
        allow(bad_commit).to receive(:refs).and_return([ref_object])
        allow_any_instance_of(Repository).to receive(:commits_between).and_return([bad_commit])

        project.create_push_rule(commit_message_regex: "Change some files")

        # push to new branch, so use a blank old rev and new ref
        expect { push_changes("#{Gitlab::Git::BLANK_SHA} #{end_sha} refs/heads/new-branch") }.not_to raise_error
      end

      it 'allows githook for any change with an old bad commit' do
        bad_commit = double("Commit", safe_message: 'Some change').as_null_object
        ref_object = double(name: 'heads/master')
        allow(bad_commit).to receive(:refs).and_return([ref_object])
        allow(project.repository).to receive(:commits_between).and_return([bad_commit])

        project.create_push_rule(commit_message_regex: "Change some files")

        # push to new branch, so use a blank old rev and new ref
        expect { push_changes("#{start_sha} #{end_sha} refs/heads/master") }.not_to raise_error
      end

      it 'does not allow any change from Web UI with bad commit' do
        bad_commit = double("Commit", safe_message: 'Some change').as_null_object
        # We use tmp ref a a temporary for Web UI commiting
        ref_object = double(name: 'refs/tmp')
        allow(bad_commit).to receive(:refs).and_return([ref_object])
        allow(project.repository).to receive(:commits_between).and_return([bad_commit])
        allow(project.repository).to receive(:new_commits).and_return([bad_commit])

        project.create_push_rule(commit_message_regex: "Change some files")

        # push to new branch, so use a blank old rev and new ref
        expect { push_changes("#{start_sha} #{end_sha} refs/heads/master") }.to raise_error(described_class::UnauthorizedError)
      end
    end

    describe "member_check" do
      let(:changes) { "#{start_sha} #{end_sha} refs/heads/master" }

      before do
        project.create_push_rule(member_check: true)
      end

      it 'returns false for non-member user' do
        expect { push_changes(changes) }.to raise_error(described_class::UnauthorizedError)
      end

      it 'returns true if committer is a gitlab member' do
        create(:user, email: 'dmitriy.zaporozhets@gmail.com')

        expect { push_changes(changes) }.not_to raise_error
      end
    end

    describe "file names check" do
      let(:start_sha) { '913c66a37b4a45b9769037c55c2d238bd0942d2e' }
      let(:end_sha) { '33f3729a45c02fc67d00adb1b8bca394b0e761d9' }
      let(:changes) { "#{start_sha} #{end_sha} refs/heads/master" }

      before do
        allow(project.repository).to receive(:new_commits)
          .and_return(project.repository.commits_between(start_sha, end_sha))
      end

      it 'returns false when filename is prohibited' do
        project.create_push_rule(file_name_regex: "jpg$")

        expect { push_changes(changes) }.to raise_error(described_class::UnauthorizedError)
      end

      it 'returns true if file name is allowed' do
        project.create_push_rule(file_name_regex: "exe$")

        expect { push_changes(changes) }.not_to raise_error
      end
    end

    describe "max file size check" do
      let(:start_sha) { ::Gitlab::Git::BLANK_SHA }
      # SHA of the 2-mb-file branch
      let(:end_sha)   { 'bf12d2567099e26f59692896f73ac819bae45b00' }
      let(:changes) { "#{start_sha} #{end_sha} refs/heads/my-branch" }

      before do
        project.add_developer(user)
        # Delete branch so Repository#new_blobs can return results
        repository.delete_branch('2-mb-file')
      end

      it "returns false when size is too large" do
        project.create_push_rule(max_file_size: 1)

        expect(repository.new_blobs(end_sha)).to be_present
        expect { push_changes(changes) }.to raise_error(described_class::UnauthorizedError)
      end

      it "returns true when size is allowed" do
        project.create_push_rule(max_file_size: 3)

        expect(repository.new_blobs(end_sha)).to be_present
        expect { push_changes(changes) }.not_to raise_error
      end
    end
  end

  describe 'repository size restrictions' do
    # SHA for the 2-mb-file branch
    let(:sha_with_2_mb_file) { 'bf12d2567099e26f59692896f73ac819bae45b00' }
    # SHA for the wip branch
    let(:sha_with_smallest_changes) { 'b9238ee5bf1d7359dd3b8c89fd76c1c7f8b75aba' }

    before do
      project.add_developer(user)
      # Delete branch so Repository#new_blobs can return results
      repository.delete_branch('2-mb-file')
      repository.delete_branch('wip')
    end

    context 'when repository size is over limit' do
      before do
        allow(project).to receive(:repository_and_lfs_size).and_return(2.megabytes)

        project.update_attribute(:repository_size_limit, 1.megabytes)
      end

      it 'rejects the push' do
        expect(repository.new_blobs(sha_with_smallest_changes)).to be_present

        expect do
          push_changes("#{Gitlab::Git::BLANK_SHA} #{sha_with_smallest_changes} refs/heads/master")
        end.to raise_error(described_class::UnauthorizedError, /Your push has been rejected/)
      end

      context 'when deleting a branch' do
        it 'accepts the operation' do
          expect do
            push_changes("#{sha_with_smallest_changes} #{::Gitlab::Git::BLANK_SHA} refs/heads/feature")
          end.not_to raise_error
        end
      end
    end

    context 'when repository size is below the limit' do
      before do
        allow(project).to receive(:repository_and_lfs_size).and_return(1.megabyte)

        project.update_attribute(:repository_size_limit, 2.megabytes)
      end

      context 'when trying to authenticate the user' do
        it 'does not raise an error' do
          expect { push_changes }.not_to raise_error
        end
      end

      context 'when pushing a new branch' do
        it 'accepts the push' do
          master_sha = project.commit('master').id

          expect do
            push_changes("#{Gitlab::Git::BLANK_SHA} #{master_sha} refs/heads/my_branch")
          end.not_to raise_error
        end
      end

      context 'when new change exceeds the limit' do
        it 'rejects the push' do
          expect(repository.new_blobs(sha_with_2_mb_file)).to be_present

          expect do
            push_changes("#{Gitlab::Git::BLANK_SHA} #{sha_with_2_mb_file} refs/heads/my_branch_2")
          end.to raise_error(described_class::UnauthorizedError, /Your push to this repository would cause it to exceed the size limit/)
        end
      end

      context 'when new change does not exceeds the limit' do
        it 'accepts the push' do
          expect(repository.new_blobs(sha_with_smallest_changes)).to be_present

          expect do
            push_changes("#{Gitlab::Git::BLANK_SHA} #{sha_with_smallest_changes} refs/heads/my_branch_3")
          end.not_to raise_error
        end
      end
    end
  end

  describe 'Geo system permissions' do
    let(:actor) { :geo }

    it { expect { pull_changes }.not_to raise_error }
    it { expect { push_changes }.to raise_unauthorized(Gitlab::GitAccess::ERROR_MESSAGES[:push_code]) }
  end

  private

  def push_changes(changes = '_any')
    access.check('git-receive-pack', changes)
  end

  def pull_changes(changes = '_any')
    access.check('git-upload-pack', changes)
  end

  def raise_unauthorized(message)
    raise_error(Gitlab::GitAccess::UnauthorizedError, message)
  end
end
