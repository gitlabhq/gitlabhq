require 'spec_helper'

describe Gitlab::Checks::ChangeAccess do
  describe '#exec' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:user_access) { Gitlab::UserAccess.new(user, project: project) }
    let(:oldrev) { 'be93687618e4b132087f430a4d8fc3a609c9b77c' }
    let(:newrev) { '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51' }
    let(:ref) { 'refs/heads/master' }
    let(:changes) { { oldrev: oldrev, newrev: newrev, ref: ref } }
    let(:protocol) { 'ssh' }

    subject(:change_access) do
      described_class.new(
        changes,
        project: project,
        user_access: user_access,
        protocol: protocol
      )
    end

    before do
      project.add_developer(user)
    end

    context 'push rules checks' do
      shared_examples 'check ignored when push rule unlicensed' do
        before do
          stub_licensed_features(push_rules: false)
        end

        it { is_expected.to be_truthy }
      end

      let(:project) { create(:project, :public, :repository, push_rule: push_rule) }

      before do
        allow(project.repository).to receive(:new_commits).and_return(
          project.repository.commits_between('be93687618e4b132087f430a4d8fc3a609c9b77c', '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51')
        )
      end

      context 'tag deletion' do
        let(:push_rule) { create(:push_rule, deny_delete_tag: true) }
        let(:oldrev) { 'be93687618e4b132087f430a4d8fc3a609c9b77c' }
        let(:newrev) { '0000000000000000000000000000000000000000' }
        let(:ref) { 'refs/tags/v1.0.0' }

        before do
          project.add_master(user)
        end

        it_behaves_like 'check ignored when push rule unlicensed'

        it 'returns an error if the rule denies tag deletion' do
          expect { subject.exec }.to raise_error(Gitlab::GitAccess::UnauthorizedError, 'You cannot delete a tag')
        end

        context 'when tag is deleted in web UI' do
          let(:protocol) { 'web' }

          it 'ignores the push rule' do
            expect(subject.exec).to be_truthy
          end
        end
      end

      context 'commit message rules' do
        let!(:push_rule) { create(:push_rule, :commit_message) }

        it_behaves_like 'check ignored when push rule unlicensed'

        it 'returns an error if the rule fails' do
          expect { subject.exec }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "Commit message does not follow the pattern '#{push_rule.commit_message_regex}'")
        end

        it 'returns an error if the regex is invalid' do
          push_rule.commit_message_regex = '+'

          expect { subject.exec }.to raise_error(Gitlab::GitAccess::UnauthorizedError, /\ARegular expression '\+' is invalid/)
        end
      end

      context 'author email rules' do
        let!(:push_rule) { create(:push_rule, author_email_regex: '.*@valid.com') }

        before do
          allow_any_instance_of(Commit).to receive(:committer_email).and_return('mike@valid.com')
          allow_any_instance_of(Commit).to receive(:author_email).and_return('mike@valid.com')
        end

        it_behaves_like 'check ignored when push rule unlicensed'

        it 'returns an error if the rule fails for the committer' do
          allow_any_instance_of(Commit).to receive(:committer_email).and_return('ana@invalid.com')

          expect { subject.exec }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "Committer's email 'ana@invalid.com' does not follow the pattern '.*@valid.com'")
        end

        it 'returns an error if the rule fails for the author' do
          allow_any_instance_of(Commit).to receive(:author_email).and_return('joan@invalid.com')

          expect { subject.exec }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "Author's email 'joan@invalid.com' does not follow the pattern '.*@valid.com'")
        end

        it 'returns an error if the regex is invalid' do
          push_rule.author_email_regex = '+'

          expect { subject.exec }.to raise_error(Gitlab::GitAccess::UnauthorizedError, /\ARegular expression '\+' is invalid/)
        end
      end

      context 'branch name rules' do
        let!(:push_rule) { create(:push_rule, branch_name_regex: '^(w*)$') }
        let(:ref) { 'refs/heads/a-branch-that-is-not-allowed' }

        it_behaves_like 'check ignored when push rule unlicensed'

        it 'rejects the branch that is not allowed' do
          expect { subject.exec }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "Branch name does not follow the pattern '^(w*)$'")
        end

        it 'returns an error if the regex is invalid' do
          push_rule.branch_name_regex = '+'

          expect { subject.exec }.to raise_error(Gitlab::GitAccess::UnauthorizedError, /\ARegular expression '\+' is invalid/)
        end

        context 'when the ref is not a branch ref' do
          let(:ref) { 'a/ref/thats/not/abranch' }

          it 'allows the creation' do
            expect { subject.exec }.not_to raise_error
          end
        end

        context 'when no commits are present' do
          before do
            allow(project.repository).to receive(:new_commits) { [] }
          end

          it 'rejects the branch that is not allowed' do
            expect { subject.exec }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "Branch name does not follow the pattern '^(w*)$'")
          end
        end

        context 'when the default branch does not match the push rules' do
          let(:push_rule) { create(:push_rule, branch_name_regex: 'not-master') }
          let(:ref) { "refs/heads/#{project.default_branch}" }

          it 'allows the default branch even if it does not match push rule' do
            expect { subject.exec }.not_to raise_error
          end

          it 'memoizes the validate_path_locks? call' do
            expect(project.path_locks).to receive(:any?).once.and_call_original

            2.times { subject.exec }
          end
        end
      end

      context 'existing member rules' do
        let(:push_rule) { create(:push_rule, member_check: true) }

        before do
          allow(User).to receive(:existing_member?).and_return(false)
          allow_any_instance_of(Commit).to receive(:author_email).and_return('some@mail.com')
        end

        it_behaves_like 'check ignored when push rule unlicensed'

        it 'returns an error if the commit author is not a GitLab member' do
          expect { subject.exec }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "Author 'some@mail.com' is not a member of team")
        end
      end

      context 'file name rules' do
        # Notice that the commit used creates a file named 'README'
        context 'file name regex check' do
          let!(:push_rule) { create(:push_rule, file_name_regex: 'READ*') }

          it_behaves_like 'check ignored when push rule unlicensed'

          it "returns an error if a new or renamed filed doesn't match the file name regex" do
            expect { subject.exec }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "File name README was blacklisted by the pattern READ*.")
          end

          it 'returns an error if the regex is invalid' do
            push_rule.file_name_regex = '+'

            expect { subject.exec }.to raise_error(Gitlab::GitAccess::UnauthorizedError, /\ARegular expression '\+' is invalid/)
          end
        end

        context 'blacklisted files check' do
          let(:push_rule) { create(:push_rule, prevent_secrets: true) }

          it_behaves_like 'check ignored when push rule unlicensed'

          it "returns true if there is no blacklisted files" do
            new_rev = nil

            white_listed =
              [
                'readme.txt', 'any/ida_rsa.pub', 'any/id_dsa.pub', 'any_2/id_ed25519.pub',
                'random_file.pdf', 'folder/id_ecdsa.pub', 'docs/aws/credentials.md', 'ending_withhistory'
              ]

            white_listed.each do |file_path|
              old_rev = 'be93687618e4b132087f430a4d8fc3a609c9b77c'
              old_rev = new_rev if new_rev
              new_rev = project.repository.create_file(user, file_path, "commit #{file_path}", message: "commit #{file_path}", branch_name: "master")

              allow(project.repository).to receive(:new_commits).and_return(
                project.repository.commits_between(old_rev, new_rev)
              )

              expect(subject.exec).to be_truthy
            end
          end

          it "returns an error if a new or renamed filed doesn't match the file name regex" do
            new_rev = nil

            black_listed =
              [
                'aws/credentials', '.ssh/personal_rsa', 'config/server_rsa', '.ssh/id_rsa', '.ssh/id_dsa',
                '.ssh/personal_dsa', 'config/server_ed25519', 'any/id_ed25519', '.ssh/personal_ecdsa', 'config/server_ecdsa',
                'any_place/id_ecdsa', 'some_pLace/file.key', 'other_PlAcE/other_file.pem', 'bye_bug.history', 'pg_sql_history'
              ]

            black_listed.each do |file_path|
              old_rev = 'be93687618e4b132087f430a4d8fc3a609c9b77c'
              old_rev = new_rev if new_rev
              new_rev = project.repository.create_file(user, file_path, "commit #{file_path}", message: "commit #{file_path}", branch_name: "master")

              allow(subject).to receive(:commits).and_return(
                project.repository.commits_between(old_rev, new_rev)
              )

              expect { subject.exec }.to raise_error(Gitlab::GitAccess::UnauthorizedError, /File name #{file_path} was blacklisted by the pattern/)
            end
          end
        end
      end

      context 'max file size rules' do
        let(:push_rule) { create(:push_rule, max_file_size: 1) }

        before do
          allow_any_instance_of(::Gitlab::Git::RawDiffChange).to receive(:blob_size).and_return(2.megabytes)
        end

        it_behaves_like 'check ignored when push rule unlicensed'

        it 'returns an error if file exceeds the maximum file size' do
          expect { subject.exec }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "File \"README\" is larger than the allowed size of 1 MB")
        end
      end

      context 'GPG sign rules' do
        before do
          stub_licensed_features(reject_unsigned_commits: true)
        end

        let(:push_rule) { create(:push_rule, reject_unsigned_commits: true) }

        it_behaves_like 'check ignored when push rule unlicensed'

        context 'when it is only enabled in Global settings' do
          before do
            project.push_rule.update_column(:reject_unsigned_commits, nil)
            create(:push_rule_sample, reject_unsigned_commits: true)
          end

          context 'and commit is not signed' do
            before do
              allow_any_instance_of(Commit).to receive(:has_signature?).and_return(false)
            end

            it 'returns an error' do
              expect { subject.exec }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "Commit must be signed with a GPG key")
            end
          end
        end

        context 'when enabled in Project' do
          context 'and commit is not signed' do
            before do
              allow_any_instance_of(Commit).to receive(:has_signature?).and_return(false)
            end

            it 'returns an error' do
              expect { subject.exec }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "Commit must be signed with a GPG key")
            end

            context 'but the change is made in the web application' do
              let(:protocol) { 'web' }

              it 'does not return an error' do
                expect { subject.exec }.not_to raise_error
              end
            end
          end

          context 'and commit is signed' do
            before do
              allow_any_instance_of(Commit).to receive(:has_signature?).and_return(true)
            end

            it 'does not return an error' do
              expect { subject.exec }.not_to raise_error
            end
          end
        end

        context 'when disabled in Project' do
          let(:push_rule) { create(:push_rule, reject_unsigned_commits: false) }

          context 'and commit is not signed' do
            before do
              allow_any_instance_of(Commit).to receive(:has_signature?).and_return(false)
            end

            it 'does not return an error' do
              expect { subject.exec }.not_to raise_error
            end
          end
        end
      end
    end

    context 'file lock rules' do
      let!(:path_lock) { create(:path_lock, path: 'README', project: project) }

      before do
        allow(project.repository).to receive(:new_commits).and_return(
          project.repository.commits_between('be93687618e4b132087f430a4d8fc3a609c9b77c', '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51')
        )
      end

      it 'returns an error if the changes update a path locked by another user' do
        expect { subject.exec }.to raise_error(Gitlab::GitAccess::UnauthorizedError, "The path 'README' is locked by #{path_lock.user.name}")
      end
    end

    context 'Check commit author rules' do
      before do
        stub_licensed_features(commit_committer_check: true)
      end

      let(:push_rule) { create(:push_rule, commit_committer_check: true) }
      let(:project) { create(:project, :public, :repository, push_rule: push_rule) }

      context 'with a commit from the authenticated user' do
        before do
          allow(project.repository).to receive(:new_commits).and_return(
            project.repository.commits_between('be93687618e4b132087f430a4d8fc3a609c9b77c', '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51')
          )
          allow_any_instance_of(Commit).to receive(:committer_email).and_return(user.email)
        end

        it 'does not return an error' do
          expect { subject.exec }.not_to raise_error
        end

        it 'allows the commit when they were done with another email that belongs to the current user' do
          user.emails.create(email: 'secondary_email@user.com', confirmed_at: Time.now)
          allow_any_instance_of(Commit).to receive(:committer_email).and_return('secondary_email@user.com')

          expect { subject.exec }.not_to raise_error
        end

        it 'raises an error when the commit was done with an unverified email' do
          user.emails.create(email: 'secondary_email@user.com')
          allow_any_instance_of(Commit).to receive(:committer_email).and_return('secondary_email@user.com')

          expect { subject.exec }
            .to raise_error(Gitlab::GitAccess::UnauthorizedError,
                            "Comitter email '%{commiter_email}' is not verified.")
        end

        it 'raises an error when using an unknown email' do
          allow_any_instance_of(Commit).to receive(:committer_email).and_return('some@mail.com')
          expect { subject.exec }
            .to raise_error(Gitlab::GitAccess::UnauthorizedError,
                            "You cannot push commits for 'some@mail.com'. You can only push commits that were committed with one of your own verified emails.")
        end
      end

      context 'for an ff merge request' do
        # the signed-commits branch fast-forwards onto master
        let(:newrev) { '2d1096e3' }

        it 'does not raise errors for a fast forward' do
          expect(change_access).not_to receive(:committer_check)
          expect { subject.exec }.not_to raise_error
        end
      end

      context 'for a normal merge' do
        # This creates a merge commit without adding it to a target branch
        # that is what the repository would look like during the `pre-receive` hook.
        #
        # That means only the merge commit should be validated.
        let(:newrev) do
          rugged = project.repository.raw_repository.rugged
          base = oldrev
          to_merge = '2d1096e3a0ecf1d2baf6dee036cc80775d4940ba'

          merge_index = rugged.merge_commits(base, to_merge)
          options = {
            parents: [base, to_merge],
            tree: merge_index.write_tree(rugged),
            message: 'The merge commit',
            author: { name: user.name, email: user.email, time: Time.now },
            committer: { name: user.name, email: user.email, time: Time.now }
          }

          Rugged::Commit.create(rugged, options)
        end

        it 'does not raise errors for a merge commit' do
          expect(change_access).to receive(:committer_check).once
                                     .and_call_original
          expect { subject.exec }.not_to raise_error
        end
      end
    end
  end
end
