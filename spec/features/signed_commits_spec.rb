require 'spec_helper'

describe 'GPG signed commits', :js do
  let(:project) { create(:project, :repository) }

  it 'changes from unverified to verified when the user changes his email to match the gpg key' do
    user = create :user, email: 'unrelated.user@example.org'
    project.team << [user, :master]

    Sidekiq::Testing.inline! do
      create :gpg_key, key: GpgHelpers::User1.public_key, user: user
    end

    sign_in(user)

    visit project_commits_path(project, :'signed-commits')

    within '#commits-list' do
      expect(page).to have_content 'Unverified'
      expect(page).not_to have_content 'Verified'
    end

    # user changes his email which makes the gpg key verified
    Sidekiq::Testing.inline! do
      user.skip_reconfirmation!
      user.update_attributes!(email: GpgHelpers::User1.emails.first)
    end

    visit project_commits_path(project, :'signed-commits')

    within '#commits-list' do
      expect(page).to have_content 'Unverified'
      expect(page).to have_content 'Verified'
    end
  end

  it 'changes from unverified to verified when the user adds the missing gpg key' do
    user = create :user, email: GpgHelpers::User1.emails.first
    project.team << [user, :master]

    sign_in(user)

    visit project_commits_path(project, :'signed-commits')

    within '#commits-list' do
      expect(page).to have_content 'Unverified'
      expect(page).not_to have_content 'Verified'
    end

    # user adds the gpg key which makes the signature valid
    Sidekiq::Testing.inline! do
      create :gpg_key, key: GpgHelpers::User1.public_key, user: user
    end

    visit project_commits_path(project, :'signed-commits')

    within '#commits-list' do
      expect(page).to have_content 'Unverified'
      expect(page).to have_content 'Verified'
    end
  end

  it 'shows popover badges' do
    gpg_user = create :user, email: GpgHelpers::User1.emails.first, username: 'nannie.bernhard', name: 'Nannie Bernhard'
    Sidekiq::Testing.inline! do
      create :gpg_key, key: GpgHelpers::User1.public_key, user: gpg_user
    end

    user = create :user
    project.team << [user, :master]

    sign_in(user)
    visit project_commits_path(project, :'signed-commits')

    # unverified signature
    click_on 'Unverified', match: :first
    within '.popover' do
      expect(page).to have_content 'This commit was signed with an unverified signature.'
      expect(page).to have_content "GPG Key ID: #{GpgHelpers::User2.primary_keyid}"
    end

    # verified and the gpg user has a gitlab profile
    click_on 'Verified', match: :first
    within '.popover' do
      expect(page).to have_content 'This commit was signed with a verified signature.'
      expect(page).to have_content 'Nannie Bernhard'
      expect(page).to have_content '@nannie.bernhard'
      expect(page).to have_content "GPG Key ID: #{GpgHelpers::User1.primary_keyid}"
    end

    # verified and the gpg user's profile doesn't exist anymore
    gpg_user.destroy!

    visit project_commits_path(project, :'signed-commits')

    click_on 'Verified', match: :first
    within '.popover' do
      expect(page).to have_content 'This commit was signed with a verified signature.'
      expect(page).to have_content 'Nannie Bernhard'
      expect(page).to have_content 'nannie.bernhard@example.com'
      expect(page).to have_content "GPG Key ID: #{GpgHelpers::User1.primary_keyid}"
    end
  end
end
