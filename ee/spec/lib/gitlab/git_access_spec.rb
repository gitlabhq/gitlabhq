require 'spec_helper'

describe Gitlab::GitAccess do
  set(:user) { create(:user) }

  let(:actor) { user }
  let(:project) { create(:project, :repository) }
  let(:protocol) { 'web' }
  let(:authentication_abilities) { %i[read_project download_code push_code] }
  let(:redirected_path) { nil }

  let(:access) { described_class.new(actor, project, protocol, authentication_abilities: authentication_abilities, redirected_path: redirected_path) }
  subject { access.check('git-receive-pack', '_any') }

  context "when in a read-only GitLab instance" do
    before do
      create(:protected_branch, name: 'feature', project: project)
      allow(Gitlab::Database).to receive(:read_only?) { true }
    end

    it 'denies push access' do
      project.add_master(user)

      expect { subject }.to raise_unauthorized("You can't push code to a read-only GitLab instance.")
    end

    it 'denies push access with primary present' do
      error_message = "You can't push code to a read-only GitLab instance."\
"\nPlease use the primary node URL instead: https://localhost:3000/gitlab/#{project.full_path}.git.
For more information: #{EE::Gitlab::GeoGitAccess::GEO_SERVER_DOCS_URL}"

      primary_node = create(:geo_node, :primary, url: 'https://localhost:3000/gitlab')
      allow(Gitlab::Geo).to receive(:primary).and_return(primary_node)
      allow(Gitlab::Geo).to receive(:secondary_with_primary?).and_return(true)

      project.add_master(user)

      expect { subject }.to raise_unauthorized(error_message)
    end
  end

  describe "push_rule_check" do
    let(:start_sha) { '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9' }
    let(:end_sha)   { '570e7b2abdd848b95f2f578043fc23bd6f6fd24d' }

    before do
      project.add_developer(user)

      allow(project.repository).to receive(:new_commits)
        .and_return(project.repository.commits_between(start_sha, end_sha))
    end

    describe "author email check" do
      it 'returns true' do
        expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.not_to raise_error
      end

      it 'returns false' do
        project.create_push_rule(commit_message_regex: "@only.com")

        expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.to raise_error(described_class::UnauthorizedError)
      end

      it 'returns true for tags' do
        project.create_push_rule(commit_message_regex: "@only.com")

        expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/tags/v1") }.not_to raise_error
      end

      it 'allows githook for new branch with an old bad commit' do
        bad_commit = double("Commit", safe_message: 'Some change').as_null_object
        ref_object = double(name: 'heads/master')
        allow(bad_commit).to receive(:refs).and_return([ref_object])
        allow_any_instance_of(Repository).to receive(:commits_between).and_return([bad_commit])

        project.create_push_rule(commit_message_regex: "Change some files")

        # push to new branch, so use a blank old rev and new ref
        expect { access.send(:check_push_access!, "#{Gitlab::Git::BLANK_SHA} #{end_sha} refs/heads/new-branch") }.not_to raise_error
      end

      it 'allows githook for any change with an old bad commit' do
        bad_commit = double("Commit", safe_message: 'Some change').as_null_object
        ref_object = double(name: 'heads/master')
        allow(bad_commit).to receive(:refs).and_return([ref_object])
        allow(project.repository).to receive(:commits_between).and_return([bad_commit])

        project.create_push_rule(commit_message_regex: "Change some files")

        # push to new branch, so use a blank old rev and new ref
        expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.not_to raise_error
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
        expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.to raise_error(described_class::UnauthorizedError)
      end
    end

    describe "member_check" do
      before do
        project.create_push_rule(member_check: true)
      end

      it 'returns false for non-member user' do
        expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.to raise_error(described_class::UnauthorizedError)
      end

      it 'returns true if committer is a gitlab member' do
        create(:user, email: 'dmitriy.zaporozhets@gmail.com')

        expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.not_to raise_error
      end
    end

    describe "file names check" do
      let(:start_sha) { '913c66a37b4a45b9769037c55c2d238bd0942d2e' }
      let(:end_sha)   { '33f3729a45c02fc67d00adb1b8bca394b0e761d9' }

      before do
        allow(project.repository).to receive(:new_commits)
          .and_return(project.repository.commits_between(start_sha, end_sha))
      end

      it 'returns false when filename is prohibited' do
        project.create_push_rule(file_name_regex: "jpg$")

        expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.to raise_error(described_class::UnauthorizedError)
      end

      it 'returns true if file name is allowed' do
        project.create_push_rule(file_name_regex: "exe$")

        expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.not_to raise_error
      end
    end

    describe "max file size check" do
      let(:start_sha) { 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660' }
      let(:end_sha)   { 'c84ff944ff4529a70788a5e9003c2b7feae29047' }

      before do
        project.add_developer(user)
      end

      it "returns false when size is too large" do
        project.create_push_rule(max_file_size: 1)

        expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.to raise_error(described_class::UnauthorizedError)
      end

      it "returns true when size is allowed" do
        project.create_push_rule(max_file_size: 2)

        expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.not_to raise_error
      end

      it "returns true when size is nil" do
        allow_any_instance_of(Gitlab::Git::Blob).to receive(:size).and_return(nil)
        project.create_push_rule(max_file_size: 2)

        expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.not_to raise_error
      end
    end
  end

  describe 'repository size restrictions' do
    let(:start_sha) { 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660' }
    let(:sha_with_2_mb_file) { 'c84ff944ff4529a70788a5e9003c2b7feae29047' }
    let(:sha_with_smallest_changes) { '33f3729a45c02fc67d00adb1b8bca394b0e761d9' }

    before do
      project.add_developer(user)
    end

    context 'when repository size is over limit' do
      before do
        allow(project).to receive(:repository_and_lfs_size).and_return(2.megabytes)

        project.update_attribute(:repository_size_limit, 1.megabytes)
      end

      it 'rejects the push' do
        expect do
          access.send(:check_push_access!, "#{start_sha} #{sha_with_smallest_changes} refs/heads/master")
        end.to raise_error(described_class::UnauthorizedError, /Your push has been rejected/)
      end
    end

    context 'when repository size is below the limit' do
      before do
        allow(project).to receive(:repository_and_lfs_size).and_return(1.megabyte)

        project.update_attribute(:repository_size_limit, 2.megabytes)
      end

      context 'when new change exceeds the limit' do
        it 'rejects the push' do
          expect do
            access.send(:check_push_access!, "#{start_sha} #{sha_with_2_mb_file} refs/heads/master")
          end.to raise_error(described_class::UnauthorizedError, /Your push to this repository would cause it to exceed the size limit/)
        end
      end

      context 'when new change does not exceeds the limit' do
        it 'accepts the push' do
          expect do
            access.send(:check_push_access!, "#{start_sha} #{sha_with_smallest_changes} refs/heads/master")
          end.not_to raise_error
        end
      end

      context 'when a file is modified' do
        # file created
        let(:old) { 'd2d430676773caa88cdaf7c55944073b2fd5561a' }
        # file modified
        let(:new) { '5f923865dde3436854e9ceb9cdb7815618d4e849' }

        before do
          # Substract 10_000 bytes in order to demostrate that the 23 KB are not added to the total
          allow(project).to receive(:repository_and_lfs_size).and_return(2.megabytes - 10000)
        end

        it 'just add the difference between the two versions to the total size' do
          expect do
            access.send(:check_push_access!, "#{old} #{new} refs/heads/master")
          end.not_to raise_error
        end
      end

      context 'when a file is renamed' do
        # file deleted
        let(:old) { '281d3a76f31c812dbf48abce82ccf6860adedd81' }
        # file added with different name
        let(:new) { 'c347ca2e140aa667b968e51ed0ffe055501fe4f4' }

        before do
          allow(project).to receive(:repository_and_lfs_size).and_return(2.megabytes)
        end

        it 'does not modify the total size given the content is the same' do
          expect do
            access.send(:check_push_access!, "#{old} #{new} refs/heads/master")
          end.not_to raise_error
        end
      end

      context 'when a file is deleted' do
        # file deleted
        let(:old) { 'c1acaa58bbcbc3eafe538cb8274ba387047b69f8' }
        # New changes introduced
        let(:new) { '5937ac0a7beb003549fc5fd26fc247adbce4a52e' }

        before do
          allow(project).to receive(:repository_and_lfs_size).and_return(2.megabytes)
        end

        it 'subtracts the size of the deleted file before calculate the new total' do
          expect do
            access.send(:check_push_access!, "#{old} #{new} refs/heads/master")
          end.not_to raise_error
        end
      end
    end
  end

  private

  def raise_unauthorized(message)
    raise_error(Gitlab::GitAccess::UnauthorizedError, message)
  end
end
