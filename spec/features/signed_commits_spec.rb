# frozen_string_literal: true

require 'spec_helper'

describe 'GPG signed commits' do
  let(:project) { create(:project, :public, :repository) }

  it 'changes from unverified to verified when the user changes his email to match the gpg key', :sidekiq_might_not_need_inline do
    ref = GpgHelpers::SIGNED_AND_AUTHORED_SHA
    user = create(:user, email: 'unrelated.user@example.org')

    perform_enqueued_jobs do
      create :gpg_key, key: GpgHelpers::User1.public_key, user: user
    end

    visit project_commit_path(project, ref)

    expect(page).to have_button 'Unverified'
    expect(page).not_to have_button 'Verified'

    # user changes his email which makes the gpg key verified
    perform_enqueued_jobs do
      user.skip_reconfirmation!
      user.update!(email: GpgHelpers::User1.emails.first)
    end

    visit project_commit_path(project, ref)

    expect(page).not_to have_button 'Unverified'
    expect(page).to have_button 'Verified'
  end

  it 'changes from unverified to verified when the user adds the missing gpg key', :sidekiq_might_not_need_inline do
    ref = GpgHelpers::SIGNED_AND_AUTHORED_SHA
    user = create(:user, email: GpgHelpers::User1.emails.first)

    visit project_commit_path(project, ref)

    expect(page).to have_button 'Unverified'
    expect(page).not_to have_button 'Verified'

    # user adds the gpg key which makes the signature valid
    perform_enqueued_jobs do
      create :gpg_key, key: GpgHelpers::User1.public_key, user: user
    end

    visit project_commit_path(project, ref)

    expect(page).not_to have_button 'Unverified'
    expect(page).to have_button 'Verified'
  end

  context 'shows popover badges', :js do
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
        create :email, user: user, email: GpgHelpers::User2.emails.last
      end
    end

    let(:user_2_key) do
      perform_enqueued_jobs do
        create :gpg_key, key: GpgHelpers::User2.public_key, user: user_2
      end
    end

    it 'unverified signature' do
      visit project_commit_path(project, GpgHelpers::SIGNED_COMMIT_SHA)

      click_on 'Unverified'

      within '.popover' do
        expect(page).to have_content 'This commit was signed with an unverified signature.'
        expect(page).to have_content "GPG Key ID: #{GpgHelpers::User2.primary_keyid}"
      end
    end

    it 'unverified signature: user email does not match the committer email, but is the same user' do
      user_2_key

      visit project_commit_path(project, GpgHelpers::DIFFERING_EMAIL_SHA)

      click_on 'Unverified'

      within '.popover' do
        expect(page).to have_content 'This commit was signed with a verified signature, but the committer email is not verified to belong to the same user.'
        expect(page).to have_content 'Bette Cartwright'
        expect(page).to have_content '@bette.cartwright'
        expect(page).to have_content "GPG Key ID: #{GpgHelpers::User2.primary_keyid}"
      end
    end

    it 'unverified signature: user email does not match the committer email' do
      user_2_key

      visit project_commit_path(project, GpgHelpers::SIGNED_COMMIT_SHA)

      click_on 'Unverified'

      within '.popover' do
        expect(page).to have_content "This commit was signed with a different user's verified signature."
        expect(page).to have_content 'Bette Cartwright'
        expect(page).to have_content '@bette.cartwright'
        expect(page).to have_content "GPG Key ID: #{GpgHelpers::User2.primary_keyid}"
      end
    end

    it 'verified and the gpg user has a gitlab profile' do
      user_1_key

      visit project_commit_path(project, GpgHelpers::SIGNED_AND_AUTHORED_SHA)

      click_on 'Verified'

      within '.popover' do
        expect(page).to have_content 'This commit was signed with a verified signature and the committer email is verified to belong to the same user.'
        expect(page).to have_content 'Nannie Bernhard'
        expect(page).to have_content '@nannie.bernhard'
        expect(page).to have_content "GPG Key ID: #{GpgHelpers::User1.primary_keyid}"
      end
    end

    it "verified and the gpg user's profile doesn't exist anymore" do
      user_1_key

      visit project_commit_path(project, GpgHelpers::SIGNED_AND_AUTHORED_SHA)

      # wait for the signature to get generated
      expect(page).to have_button 'Verified'

      user_1.destroy!

      refresh

      click_on 'Verified'

      within '.popover' do
        expect(page).to have_content 'This commit was signed with a verified signature and the committer email is verified to belong to the same user.'
        expect(page).to have_content 'Nannie Bernhard'
        expect(page).to have_content 'nannie.bernhard@example.com'
        expect(page).to have_content "GPG Key ID: #{GpgHelpers::User1.primary_keyid}"
      end
    end
  end

  context 'view signed commit on the tree view', :js do
    shared_examples 'a commit with a signature' do
      before do
        visit project_tree_path(project, 'signed-commits')
      end

      it 'displays commit signature' do
        expect(page).to have_button 'Unverified'

        click_on 'Unverified'

        within '.popover' do
          expect(page).to have_content 'This commit was signed with an unverified signature'
        end
      end
    end

    context 'with vue tree view enabled' do
      it_behaves_like 'a commit with a signature'
    end
  end
end
