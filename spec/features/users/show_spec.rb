# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User page', feature_category: :user_profile do
  include ExternalAuthorizationServiceHelpers

  let_it_be(:user) { create(:user, bio: '<b>Lorem</b> <i>ipsum</i> dolor sit <a href="https://example.com">amet</a>') }

  subject(:visit_profile) { visit(user_path(user)) }

  it 'shows copy user id action in the dropdown', :js do
    subject

    page.within('.cover-controls') do
      find_by_testid('base-dropdown-toggle').click
    end

    expect(page).to have_content("Copy user ID: #{user.id}")
  end

  it 'shows name on breadcrumbs', :js do
    subject

    within_testid('breadcrumb-links') do
      expect(page).to have_content(user.name)
    end
  end

  context 'with public profile' do
    it 'does not show private profile message' do
      subject

      expect(page).not_to have_content("This user has a private profile")
    end

    context 'work information' do
      it 'shows job title and organization details' do
        user.update!(organization: 'GitLab - work info test', job_title: 'Frontend Engineer')

        subject

        expect(page).to have_content('Frontend Engineer at GitLab - work info test')
      end

      it 'shows job title' do
        user.update!(organization: nil, job_title: 'Frontend Engineer - work info test')

        subject

        expect(page).to have_content('Frontend Engineer - work info test')
      end

      it 'shows organization details' do
        user.update!(organization: 'GitLab - work info test', job_title: '')

        subject

        expect(page).to have_content('GitLab - work info test')
      end
    end

    context 'location' do
      let_it_be(:location) { 'San Francisco, CA' }

      context 'when location is set' do
        let_it_be(:user) { create(:user, location: location) }

        it 'shows location' do
          subject

          expect(page).to have_content(location)
        end
      end

      context 'when location is not set' do
        it 'does not show location' do
          subject

          expect(page).not_to have_content(location)
        end
      end
    end

    context 'timezone' do
      let_it_be(:timezone) { 'America/Los_Angeles' }
      let_it_be(:local_time_selector) { '[data-testid="user-local-time"]' }

      before do
        travel_to Time.find_zone(timezone).local(2021, 7, 20, 15, 30, 45)
      end

      context 'when timezone is set' do
        let_it_be(:user) { create(:user, timezone: timezone) }

        it 'shows local time' do
          subject

          within local_time_selector do
            expect(page).to have_content('3:30 PM')
          end
        end
      end

      context 'when timezone is not set' do
        let_it_be(:user) { create(:user, timezone: nil) }

        it 'does not show local time' do
          subject

          expect(page).not_to have_selector(local_time_selector)
        end
      end

      context 'when timezone is invalid' do
        let_it_be(:user) { create(:user, timezone: 'Foo/Bar') }

        it 'shows local time using the configured default timezone (UTC in this case)' do
          subject

          within local_time_selector do
            expect(page).to have_content('10:30 PM')
          end
        end
      end
    end

    context 'follow/unfollow and followers/following', :js do
      let_it_be(:followee) { create(:user) }
      let_it_be(:follower) { create(:user) }

      it 'does not show button to follow' do
        subject

        expect(page).not_to have_button(text: 'Follow', class: 'gl-button')
      end

      shared_examples 'follower links with count badges' do
        it 'shows no count if no followers / following' do
          subject

          within_testid('super-sidebar') do
            expect(page).to have_link(text: 'Followers')
            expect(page).to have_link(text: 'Following')
          end
        end

        it 'shows count if followers / following' do
          follower.follow(user)
          user.follow(followee)

          subject

          within_testid('super-sidebar') do
            expect(page).to have_link(text: 'Followers 1')
            expect(page).to have_link(text: 'Following 1')
          end
        end
      end

      context 'with profile_tabs_vue feature flag disabled' do
        before do
          stub_feature_flags(profile_tabs_vue: false)
        end

        it_behaves_like 'follower links with count badges'
      end

      it 'does show button to follow' do
        sign_in(user)
        visit user_path(followee)

        expect(page).to have_button(text: 'Follow', class: 'gl-button')
      end

      it 'does show link to unfollow' do
        sign_in(user)
        user.follow(followee)

        visit user_path(followee)

        expect(page).to have_button(text: 'Unfollow', class: 'gl-button')
      end
    end
  end

  context 'with private profile' do
    let_it_be(:user) { create(:user, private_profile: true) }

    it 'shows no page content container', :aggregate_failures do
      subject

      expect(page).to have_css("div.profile-header")
      expect(page).not_to have_css("#js-legacy-tabs-container")
    end

    it 'shows private profile message' do
      subject

      expect(page).to have_content("This user has a private profile")
      expect(page).not_to have_content("Info")
      expect(page).not_to have_content("Member since")
    end
  end

  context 'with blocked profile' do
    let_it_be(:user) do
      create(
        :user,
        state: :blocked,
        organization: 'GitLab - work info test',
        job_title: 'Frontend Engineer',
        pronunciation: 'pruh-nuhn-see-ay-shn',
        bio: 'My personal bio'
      )
    end

    let_it_be(:status) { create(:user_status, user: user, message: "Working hard!") }

    before do
      visit_profile
    end

    it 'shows no content container' do
      expect(page).not_to have_css("div.profile-header")
      expect(page).not_to have_css("#js-legacy-tabs-container")
    end

    it 'shows no sidebar' do
      expect(page).not_to have_css(".user-profile-sidebar")
    end

    it 'shows blocked message' do
      expect(page).to have_content("This user is blocked")
    end

    it 'shows user name as blocked' do
      expect(page).to have_css('[data-testid="user-profile-header"]', text: 'Blocked user')
    end

    it 'shows no additional fields' do
      expect(page).not_to have_css(".profile-user-bio")
      expect(page).not_to have_content('GitLab - work info test')
      expect(page).not_to have_content('Frontend Engineer')
      expect(page).not_to have_content('Working hard!')
      expect(page).not_to have_content("Pronounced as: pruh-nuhn-see-ay-shn")
    end

    it 'shows username' do
      expect(page).to have_content("@#{user.username}")
    end

    it_behaves_like 'default brand title page meta description'
  end

  context 'with unconfirmed user' do
    let_it_be(:user) do
      create(
        :user,
        :unconfirmed,
        organization: 'GitLab - work info test',
        job_title: 'Frontend Engineer',
        pronunciation: 'pruh-nuhn-see-ay-shn',
        bio: 'My personal bio'
      )
    end

    let_it_be(:status) { create(:user_status, user: user, message: "Working hard!") }

    shared_examples 'unconfirmed user profile' do
      before do
        visit_profile
      end

      it 'shows user name as unconfirmed' do
        expect(page).to have_css('[data-testid="user-profile-header"]', text: 'Unconfirmed user')
      end

      it 'shows no content container' do
        expect(page).to have_css('[data-testid="user-profile-header"]')
        expect(page).not_to have_css("#js-legacy-tabs-container")
      end

      it 'shows no additional fields' do
        expect(page).not_to have_css(".profile-user-bio")
        expect(page).not_to have_content('GitLab - work info test')
        expect(page).not_to have_content('Frontend Engineer')
        expect(page).not_to have_content('Working hard!')
        expect(page).not_to have_content("Pronounced as: pruh-nuhn-see-ay-shn")
      end

      it 'shows private profile message' do
        expect(page).to have_content("This user has a private profile")
      end

      it_behaves_like 'default brand title page meta description'
    end

    context 'when visited by an authenticated user' do
      before do
        authenticated_user = create(:user)
        sign_in(authenticated_user)
      end

      it_behaves_like 'unconfirmed user profile'
    end

    context 'when visited by an unauthenticated user' do
      it_behaves_like 'unconfirmed user profile'
    end
  end

  it 'shows the status if there was one' do
    create(:user_status, user: user, message: "Working hard!")

    subject

    expect(page).to have_content("Working hard!")
  end

  it 'shows the pronouns of the user if there was one' do
    user.user_detail.update_column(:pronouns, 'they/them')

    subject

    expect(page).to have_content("Pronouns: they/them")
  end

  it 'shows the pronunctiation of the user if there was one' do
    user.user_detail.update_column(:pronunciation, 'pruh-nuhn-see-ay-shn')

    subject

    expect(page).to have_content("Pronounced as: pruh-nuhn-see-ay-shn")
  end

  context 'signup disabled' do
    it 'shows the sign in link' do
      stub_application_setting(signup_enabled: false)

      subject

      within_testid('navbar') do
        expect(page).to have_link('Sign in')
        expect(page).not_to have_link('Register')
      end
    end
  end

  context 'signup enabled' do
    it 'shows the sign in and register link' do
      stub_application_setting(signup_enabled: true)

      subject

      within_testid('navbar') do
        expect(page).to have_link(_('Sign in'), exact: true)
        expect(page).to have_link(_('Register'), exact: true)
      end
    end
  end

  context 'most recent activity' do
    before do
      stub_feature_flags(profile_tabs_vue: false)
    end

    context 'when external authorization is enabled' do
      before do
        enable_external_authorization_service_check
      end

      it 'hides the most recent activity' do
        subject

        expect(page).not_to have_content('Most Recent Activity')
      end
    end
  end

  context 'page description' do
    before do
      subject
    end

    it_behaves_like 'page meta description', 'Lorem ipsum dolor sit amet'
  end

  context 'structured markup' do
    let_it_be(:user) { create(:user, website_url: 'https://gitlab.com', organization: 'GitLab', job_title: 'Frontend Engineer', email: 'public@example.com', public_email: 'public@example.com', location: 'Country', created_at: Time.zone.now, updated_at: Time.zone.now) }

    it 'shows Person structured markup' do
      subject

      aggregate_failures do
        expect(page).to have_selector('[itemscope][itemtype="http://schema.org/Person"]')
        expect(page).to have_selector('img[itemprop="image"]')
        expect(page).to have_selector('[itemprop="name"]')
        expect(page).to have_selector('[itemprop="address"][itemscope][itemtype="https://schema.org/PostalAddress"]')
        expect(page).to have_selector('[itemprop="addressLocality"]')
        expect(page).to have_selector('[itemprop="url"]')
        expect(page).to have_selector('[itemprop="email"]')
        expect(page).to have_selector('span[itemprop="jobTitle"]')
        expect(page).to have_selector('span[itemprop="worksFor"]')
      end
    end
  end

  context 'GPG keys' do
    context 'when user has verified GPG keys' do
      let_it_be(:user) { create(:user, email: GpgHelpers::User1.emails.first) }
      let_it_be(:gpg_key) { create(:gpg_key, user: user, key: GpgHelpers::User1.public_key) }
      let_it_be(:gpg_key2) { create(:gpg_key, user: user, key: GpgHelpers::User1.public_key2) }

      it 'shows link to public GPG keys' do
        subject

        expect(page).to have_link('View public GPG keys', href: user_gpg_keys_path(user))
      end
    end

    context 'when user does not have verified GPG keys' do
      it 'does not show link to public GPG keys' do
        subject

        expect(page).not_to have_link('View public GPG key', href: user_gpg_keys_path(user))
        expect(page).not_to have_link('View public GPG keys', href: user_gpg_keys_path(user))
      end
    end
  end

  context 'achievements' do
    it 'renders the user achievements mount point' do
      subject

      expect(page).to have_selector('#js-user-achievements')
    end

    context 'when the user has chosen not to display achievements' do
      let(:user) { create(:user) }

      before do
        user.update!(achievements_enabled: false)
      end

      it 'does not render the user achievements mount point' do
        subject

        expect(page).not_to have_selector('#js-user-achievements')
      end
    end

    context 'when the profile is private' do
      let(:user) { create(:user, private_profile: true) }

      it 'does not render the user achievements mount point' do
        subject

        expect(page).not_to have_selector('#js-user-achievements')
      end
    end
  end
end
