# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GPG signed commits', :js, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :public, :repository) }

  it 'changes from unverified to verified when the user changes their email to match the gpg key', :sidekiq_might_not_need_inline do
    ref = GpgHelpers::SIGNED_AND_AUTHORED_SHA
    user = create(:user, email: 'unrelated.user@example.org')

    perform_enqueued_jobs do
      create :gpg_key, key: GpgHelpers::User1.public_key, user: user
      user.reload # necessary to reload the association with gpg_keys
    end

    visit project_commit_path(project, ref)

    expect(page).to have_selector('.gl-badge', text: 'Unverified')

    # user changes their email which makes the gpg key verified
    perform_enqueued_jobs do
      user.skip_reconfirmation!
      user.update!(email: GpgHelpers::User1.emails.first)
    end

    visit project_commit_path(project, ref)

    expect(page).to have_selector('.gl-badge', text: 'Verified')
  end

  it 'changes from unverified to verified when the user adds the missing gpg key', :sidekiq_might_not_need_inline do
    ref = GpgHelpers::SIGNED_AND_AUTHORED_SHA
    user = create(:user, email: GpgHelpers::User1.emails.first)

    visit project_commit_path(project, ref)

    expect(page).to have_selector('.gl-badge', text: 'Unverified')

    # user adds the gpg key which makes the signature valid
    perform_enqueued_jobs do
      create :gpg_key, key: GpgHelpers::User1.public_key, user: user
    end

    visit project_commit_path(project, ref)

    expect(page).to have_selector('.gl-badge', text: 'Verified')
  end

  context 'shows popover badges' do
    let(:user_1) do
      create :user, email: GpgHelpers::User1.emails.first, username: 'nannie.bernhard', name: 'Nannie Bernhard'
    end

    let(:user_1_key) do
      perform_enqueued_jobs do
        create :gpg_key, key: GpgHelpers::User1.public_key, user: user_1
      end
    end

    let(:user_2) do
      create(:user, email: GpgHelpers::User2.emails.first, username: 'bette.cartwright', name: 'Bette Cartwright').tap do |user|
        # secondary, unverified email
        create :email, user: user, email: 'mail@koffeinfrei.org'
      end
    end

    let(:user_2_key) do
      perform_enqueued_jobs do
        create :gpg_key, key: GpgHelpers::User2.public_key, user: user_2
      end
    end

    it 'unverified signature', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/444982' do
      visit project_commit_path(project, GpgHelpers::SIGNED_COMMIT_SHA)
      wait_for_all_requests

      page.find('.gl-badge', text: 'Unverified').click

      within '.popover' do
        expect(page).to have_content 'This commit was signed with an unverified signature.'
        expect(page).to have_content "GPG Key ID: #{GpgHelpers::User2.primary_keyid}"
      end
    end

    it 'unverified signature: gpg key email does not match the committer_email but is the same user when the committer_email belongs to the user as a confirmed secondary email', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/444984' do
      user_2_key
      user_2.emails.find_by(email: 'mail@koffeinfrei.org').confirm

      visit project_commit_path(project, GpgHelpers::SIGNED_COMMIT_SHA)
      wait_for_all_requests

      page.find('.gl-badge', text: 'Unverified').click

      within '.popover' do
        expect(page).to have_content 'This commit was signed with a verified signature, but the committer email is not associated with the GPG Key.'
        expect(page).to have_content "GPG Key ID: #{GpgHelpers::User2.primary_keyid}"
      end
    end

    it 'unverified signature: gpg key email does not match the committer_email when the committer_email belongs to the user as a unconfirmed secondary email',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/408233' do
      user_2_key

      visit project_commit_path(project, GpgHelpers::SIGNED_COMMIT_SHA)
      wait_for_all_requests

      page.find('.gl-badge', text: 'Unverified').click

      within '.popover' do
        expect(page).to have_content "This commit was signed with a different user's verified signature."
        expect(page).to have_content "GPG Key ID: #{GpgHelpers::User2.primary_keyid}"
      end
    end

    it 'unverified signature: commit contains multiple GPG signatures', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/408233' do
      user_1_key

      visit project_commit_path(project, GpgHelpers::MULTIPLE_SIGNATURES_SHA)
      wait_for_all_requests

      page.find('.gl-badge', text: 'Unverified').click

      within '.popover' do
        expect(page).to have_content "This commit was signed with multiple signatures."
      end
    end

    it 'verified and the gpg user has a gitlab profile', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/408233' do
      user_1_key

      visit project_commit_path(project, GpgHelpers::SIGNED_AND_AUTHORED_SHA)
      wait_for_all_requests

      page.find('.gl-badge', text: 'Verified').click

      within '.popover' do
        expect(page).to have_content 'This commit was signed with a verified signature and the committer email was verified to belong to the same user.'
        expect(page).to have_content "GPG Key ID: #{GpgHelpers::User1.primary_keyid}"
      end
    end

    it "verified and the gpg user's profile doesn't exist anymore", quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/395802' do
      user_1_key

      visit project_commit_path(project, GpgHelpers::SIGNED_AND_AUTHORED_SHA)
      wait_for_all_requests

      # wait for the signature to get generated
      expect(page).to have_selector('.gl-badge', text: 'Verified')

      user_1.destroy!

      refresh
      wait_for_all_requests

      page.find('.gl-badge', text: 'Verified').click

      within '.popover' do
        expect(page).to have_content 'This commit was signed with a verified signature and the committer email was verified to belong to the same user.'
        expect(page).to have_content "GPG Key ID: #{GpgHelpers::User1.primary_keyid}"
      end
    end

    # The below situation can occur when using the git mailmap feature.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/425042.
    describe 'the effect of mailmapping' do
      def expect_to_have_label_content(ref, message, fingerprint_message)
        visit project_commit_path(project, ref)
        wait_for_all_requests

        page.find('.gl-badge', text: 'Verified').click

        within '.popover' do
          expect(page).to have_content message
          expect(page).to have_content fingerprint_message
        end
      end

      context 'on SSH signed commits' do
        let(:commit) { project.commit('7b5160f9bb23a3d58a0accdbe89da13b96b1ece9') }
        let(:message) { 'This commit was signed with a verified signature and the committer email was verified to belong to the same user.' }
        let(:mapped_message) { 'This commit was previously signed with a verified signature and verified committer email address. However the committer email address is no longer verified to the same user.' }

        context 'when user commit email is not verified and the commit is signed and verified' do
          let(:commit) { project.commit('7b5160f9bb23a3d58a0accdbe89da13b96b1ece9') }
          let(:fingerprint) { commit.signature.key_fingerprint_sha256 }

          before do
            create(:ssh_signature, user: user_1, commit_sha: commit.sha, project: project, verification_status: :verified)
          end

          it 'label is mapped verified' do
            expect_to_have_label_content(commit.sha, mapped_message, "SSH key fingerprint: #{fingerprint}")
          end

          context 'when the check_for_mailmapped_commit_emails feature flag is disabled' do
            before do
              stub_feature_flags(check_for_mailmapped_commit_emails: false)
            end

            it 'label is verified' do
              expect_to_have_label_content(commit.sha, message, "SSH key fingerprint: #{fingerprint}")
            end
          end
        end
      end

      context 'on GPG on signed commits' do
        let(:commit) { project.commit(GpgHelpers::SIGNED_COMMIT_SHA) }
        let(:message) { 'This commit was signed with a verified signature and the committer email was verified to belong to the same user.' }
        let(:mapped_message) { 'This commit was previously signed with a verified signature and verified committer email address. However the committer email address is no longer verified to the same user.' }

        context 'when user commit email is not verified and the commit is signed and verified' do
          let(:fingerprint) { GpgHelpers::User1.primary_keyid }

          before do
            create(
              :gpg_signature,
              commit_sha: commit.sha,
              gpg_key: (create :gpg_key, user: user_1),
              project: project,
              verification_status: :verified
            )

            allow(commit).to receive(:author_email).and_return('unverified@email.org')
          end

          it 'label is mapped verified' do
            expect_to_have_label_content(commit.sha, mapped_message, "GPG Key ID: #{fingerprint}")
          end

          context 'when the check_for_mailmapped_commit_emails feature flag is disabled' do
            before do
              stub_feature_flags(check_for_mailmapped_commit_emails: false)
            end

            it 'label is verified' do
              expect_to_have_label_content(commit.sha, message, "GPG Key ID: #{fingerprint}")
            end
          end
        end
      end

      context 'on x509 on signed commits' do
        let_it_be(:commit_sha) { '189a6c924013fc3fe40d6f1ec1dc20214183bc97' }
        let_it_be(:commit) { create(:commit, project: project, sha: commit_sha) }
        let_it_be(:x509_certificate) { create(:x509_certificate, email: 'r.meier@siemens.com') }
        let_it_be(:user) { create(:user, email: 'gitlab@example.org') }
        let(:message) { 'This commit was signed with a verified signature and the committer email is verified to belong to the same user.' }
        let(:mapped_message) { 'This commit was previously signed with a verified signature and verified committer email address. However the committer email address is no longer verified to the same user.' }
        let(:fingerprint) { x509_certificate.subject_key_identifier.tr(':', ' ') }

        let(:attributes) do
          {
            commit_sha: commit_sha,
            project: project,
            x509_certificate_id: x509_certificate.id,
            verification_status: "verified"
          }
        end

        let(:signature) { create(:x509_commit_signature, commit_sha: commit_sha, x509_certificate: x509_certificate, project: project) }

        before do
          signature
        end

        context 'happy path - no mapping' do
          it 'label is verified' do
            expect_to_have_label_content(commit.sha, message, fingerprint)
          end
        end

        context 'when user commit email is not verified and the commit is signed and verified' do
          let(:x509_certificate) { create(:x509_certificate, email: 'gitlab@example.org') }

          it 'label is mapped verified' do
            expect_to_have_label_content(commit.sha, mapped_message, fingerprint)
          end

          context 'when the check_for_mailmapped_commit_emails feature flag is disabled' do
            before do
              stub_feature_flags(check_for_mailmapped_commit_emails: false)
            end

            it 'label is verified' do
              expect_to_have_label_content(commit.sha, message, fingerprint)
            end
          end
        end
      end
    end
  end

  context 'view signed commit on the tree view' do
    shared_examples 'a commit with a signature' do
      before do
        visit project_tree_path(project, 'signed-commits')
        wait_for_all_requests
      end

      it 'displays commit signature' do
        expect(page).to have_selector('.gl-badge', text: 'Unverified')

        page.find('.gl-badge', text: 'Unverified').click

        within '.popover' do
          expect(page).to have_content 'This commit was signed with multiple signatures.'
        end
      end
    end

    context 'with vue tree view enabled' do
      it_behaves_like 'a commit with a signature'
    end
  end
end
