require 'spec_helper'

describe 'GPG signed commits', :js do
  set(:ref) { :'2d1096e3a0ecf1d2baf6dee036cc80775d4940ba' }
  let(:project) { create(:project, :repository) }

  it 'changes from unverified to verified when the user changes his email to match the gpg key' do
    user = create :user, email: 'unrelated.user@example.org'
    project.add_maintainer(user)

    perform_enqueued_jobs do
      create :gpg_key, key: GpgHelpers::User1.public_key, user: user
    end

    sign_in(user)

    visit project_commits_path(project, ref)

    within '#commits-list' do
      expect(page).to have_content 'Unverified'
      expect(page).not_to have_content 'Verified'
    end

    # user changes his email which makes the gpg key verified
    perform_enqueued_jobs do
      user.skip_reconfirmation!
      user.update!(email: GpgHelpers::User1.emails.first)
    end

    visit project_commits_path(project, ref)

    within '#commits-list' do
      expect(page).to have_content 'Unverified'
      expect(page).to have_content 'Verified'
    end
  end

  it 'changes from unverified to verified when the user adds the missing gpg key' do
    user = create :user, email: GpgHelpers::User1.emails.first
    project.add_maintainer(user)

    sign_in(user)

    visit project_commits_path(project, ref)

    within '#commits-list' do
      expect(page).to have_content 'Unverified'
      expect(page).not_to have_content 'Verified'
    end

    # user adds the gpg key which makes the signature valid
    perform_enqueued_jobs do
      create :gpg_key, key: GpgHelpers::User1.public_key, user: user
    end

    visit project_commits_path(project, ref)

    within '#commits-list' do
      expect(page).to have_content 'Unverified'
      expect(page).to have_content 'Verified'
    end
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
        create :email, user: user, email: GpgHelpers::User2.emails.last
      end
    end

    let(:user_2_key) do
      perform_enqueued_jobs do
        create :gpg_key, key: GpgHelpers::User2.public_key, user: user_2
      end
    end

    before do
      user = create :user
      project.add_maintainer(user)

      sign_in(user)
    end

    it 'unverified signature' do
      visit project_commits_path(project, ref)

      within(find('.commit', text: 'signed commit by bette cartwright')) do
        click_on 'Unverified'
      end

      within '.popover' do
        expect(page).to have_content 'This commit was signed with an unverified signature.'
        expect(page).to have_content "GPG Key ID: #{GpgHelpers::User2.primary_keyid}"
      end
    end

    it 'unverified signature: user email does not match the committer email, but is the same user' do
      user_2_key

      visit project_commits_path(project, ref)

      within(find('.commit', text: 'signed and authored commit by bette cartwright, different email')) do
        click_on 'Unverified'
      end

      within '.popover' do
        expect(page).to have_content 'This commit was signed with a verified signature, but the committer email is not verified to belong to the same user.'
        expect(page).to have_content 'Bette Cartwright'
        expect(page).to have_content '@bette.cartwright'
        expect(page).to have_content "GPG Key ID: #{GpgHelpers::User2.primary_keyid}"
      end
    end

    it 'unverified signature: user email does not match the committer email' do
      user_2_key

      visit project_commits_path(project, ref)

      within(find('.commit', text: 'signed commit by bette cartwright')) do
        click_on 'Unverified'
      end

      within '.popover' do
        expect(page).to have_content "This commit was signed with a different user's verified signature."
        expect(page).to have_content 'Bette Cartwright'
        expect(page).to have_content '@bette.cartwright'
        expect(page).to have_content "GPG Key ID: #{GpgHelpers::User2.primary_keyid}"
      end
    end

    it 'verified and the gpg user has a gitlab profile' do
      user_1_key

      visit project_commits_path(project, ref)

      within(find('.commit', text: 'signed and authored commit by nannie bernhard')) do
        click_on 'Verified'
      end

      within '.popover' do
        expect(page).to have_content 'This commit was signed with a verified signature and the committer email is verified to belong to the same user.'
        expect(page).to have_content 'Nannie Bernhard'
        expect(page).to have_content '@nannie.bernhard'
        expect(page).to have_content "GPG Key ID: #{GpgHelpers::User1.primary_keyid}"
      end
    end

    it "verified and the gpg user's profile doesn't exist anymore" do
      user_1_key

      visit project_commits_path(project, ref)

      # wait for the signature to get generated
      within(find('.commit', text: 'signed and authored commit by nannie bernhard')) do
        expect(page).to have_content 'Verified'
      end

      user_1.destroy!

      refresh

      within(find('.commit', text: 'signed and authored commit by nannie bernhard')) do
        click_on 'Verified'
      end

      within '.popover' do
        expect(page).to have_content 'This commit was signed with a verified signature and the committer email is verified to belong to the same user.'
        expect(page).to have_content 'Nannie Bernhard'
        expect(page).to have_content 'nannie.bernhard@example.com'
        expect(page).to have_content "GPG Key ID: #{GpgHelpers::User1.primary_keyid}"
      end
    end
  end
end
