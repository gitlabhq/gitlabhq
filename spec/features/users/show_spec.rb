# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User page' do
  include ExternalAuthorizationServiceHelpers

  let_it_be(:user) { create(:user, bio: '**Lorem** _ipsum_ dolor sit [amet](https://example.com)') }

  subject(:visit_profile) { visit(user_path(user)) }

  context 'with public profile' do
    it 'shows all the tabs' do
      subject

      page.within '.nav-links' do
        expect(page).to have_link('Overview')
        expect(page).to have_link('Activity')
        expect(page).to have_link('Groups')
        expect(page).to have_link('Contributed projects')
        expect(page).to have_link('Personal projects')
        expect(page).to have_link('Snippets')
        expect(page).to have_link('Followers')
        expect(page).to have_link('Following')
      end
    end

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

    context 'follow/unfollow and followers/following' do
      let_it_be(:followee) { create(:user) }
      let_it_be(:follower) { create(:user) }

      it 'does not show link to follow' do
        subject

        expect(page).not_to have_link(text: 'Follow', class: 'gl-button')
      end

      it 'shows 0 followers and 0 following' do
        subject

        expect(page).to have_content('0 followers')
        expect(page).to have_content('0 following')
      end

      it 'shows 1 followers and 1 following' do
        follower.follow(user)
        user.follow(followee)

        subject

        expect(page).to have_content('1 follower')
        expect(page).to have_content('1 following')
      end

      it 'does show link to follow' do
        sign_in(user)
        visit user_path(followee)

        expect(page).to have_link(text: 'Follow', class: 'gl-button')
      end

      it 'does show link to unfollow' do
        sign_in(user)
        user.follow(followee)

        visit user_path(followee)

        expect(page).to have_link(text: 'Unfollow', class: 'gl-button')
      end
    end
  end

  context 'with private profile' do
    let_it_be(:user) { create(:user, private_profile: true) }

    it 'shows no tab' do
      subject

      expect(page).to have_css("div.profile-header")
      expect(page).not_to have_css("ul.nav-links")
    end

    it 'shows private profile message' do
      subject

      expect(page).to have_content("This user has a private profile")
    end

    it 'shows own tabs' do
      sign_in(user)
      subject

      page.within '.nav-links' do
        expect(page).to have_link('Overview')
        expect(page).to have_link('Activity')
        expect(page).to have_link('Groups')
        expect(page).to have_link('Contributed projects')
        expect(page).to have_link('Personal projects')
        expect(page).to have_link('Snippets')
        expect(page).to have_link('Followers')
        expect(page).to have_link('Following')
      end
    end
  end

  context 'with blocked profile' do
    let_it_be(:user) { create(:user, state: :blocked) }

    it 'shows no tab' do
      subject

      expect(page).to have_css("div.profile-header")
      expect(page).not_to have_css("ul.nav-links")
    end

    it 'shows blocked message' do
      subject

      expect(page).to have_content("This user is blocked")
    end

    it 'shows user name as blocked' do
      subject

      expect(page).to have_css(".cover-title", text: 'Blocked user')
    end

    it 'shows no additional fields' do
      subject

      expect(page).not_to have_css(".profile-user-bio")
      expect(page).not_to have_css(".profile-link-holder")
    end

    it 'shows username' do
      subject

      expect(page).to have_content("@#{user.username}")
    end
  end

  context 'with unconfirmed user' do
    let_it_be(:user) { create(:user, :unconfirmed) }

    shared_examples 'unconfirmed user profile' do
      before do
        visit_profile
      end

      it 'shows user name as unconfirmed' do
        expect(page).to have_css(".cover-title", text: 'Unconfirmed user')
      end

      it 'shows no tab' do
        expect(page).to have_css("div.profile-header")
        expect(page).not_to have_css("ul.nav-links")
      end

      it 'shows no additional fields' do
        expect(page).not_to have_css(".profile-user-bio")
        expect(page).not_to have_css(".profile-link-holder")
      end

      it 'shows private profile message' do
        expect(page).to have_content("This user has a private profile")
      end
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

    expect(page).to have_content("(they/them)")
  end

  context 'signup disabled' do
    it 'shows the sign in link' do
      stub_application_setting(signup_enabled: false)

      subject

      page.within '.navbar-nav' do
        expect(page).to have_link('Sign in')
      end
    end
  end

  context 'signup enabled' do
    it 'shows the sign in and register link' do
      stub_application_setting(signup_enabled: true)

      subject

      page.within '.navbar-nav' do
        expect(page).to have_link('Sign in / Register')
      end
    end
  end

  context 'most recent activity' do
    it 'shows the most recent activity' do
      subject

      expect(page).to have_content('Most Recent Activity')
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

  context 'with a bot user' do
    let_it_be(:user) { create(:user, user_type: :security_bot) }

    describe 'feature flag enabled' do
      before do
        stub_feature_flags(security_auto_fix: true)
      end

      it 'only shows Overview and Activity tabs' do
        subject

        page.within '.nav-links' do
          expect(page).to have_link('Overview')
          expect(page).to have_link('Activity')
          expect(page).not_to have_link('Groups')
          expect(page).not_to have_link('Contributed projects')
          expect(page).not_to have_link('Personal projects')
          expect(page).not_to have_link('Snippets')
          expect(page).not_to have_link('Followers')
          expect(page).not_to have_link('Following')
        end
      end
    end

    describe 'feature flag disabled' do
      before do
        stub_feature_flags(security_auto_fix: false)
      end

      it 'only shows Overview and Activity tabs' do
        subject

        page.within '.nav-links' do
          expect(page).to have_link('Overview')
          expect(page).to have_link('Activity')
          expect(page).to have_link('Groups')
          expect(page).to have_link('Contributed projects')
          expect(page).to have_link('Personal projects')
          expect(page).to have_link('Snippets')
          expect(page).to have_link('Followers')
          expect(page).to have_link('Following')
        end
      end
    end
  end

  context 'structured markup' do
    let_it_be(:user) { create(:user, website_url: 'https://gitlab.com', organization: 'GitLab', job_title: 'Frontend Engineer', email: 'public@example.com', public_email: 'public@example.com', location: 'Country', created_at: Time.now, updated_at: Time.now) }

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
end
