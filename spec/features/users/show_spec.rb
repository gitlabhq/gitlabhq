require 'spec_helper'

describe 'User page' do
  let(:user) { create(:user) }

  context 'with public profile' do
    it 'shows all the tabs' do
      visit(user_path(user))

      page.within '.nav-links' do
        expect(page).to have_link('Activity')
        expect(page).to have_link('Groups')
        expect(page).to have_link('Contributed projects')
        expect(page).to have_link('Personal projects')
        expect(page).to have_link('Snippets')
      end
    end

    it 'does not show private profile message' do
      visit(user_path(user))

      expect(page).not_to have_content("This user has a private profile")
    end
  end

  context 'with private profile' do
    let(:user) { create(:user, private_profile: true) }

    it 'shows no tab' do
      visit(user_path(user))

      expect(page).to have_css("div.profile-header")
      expect(page).not_to have_css("ul.nav-links")
    end

    it 'shows private profile message' do
      visit(user_path(user))

      expect(page).to have_content("This user has a private profile")
    end

    it 'shows own tabs' do
      sign_in(user)
      visit(user_path(user))

      page.within '.nav-links' do
        expect(page).to have_link('Activity')
        expect(page).to have_link('Groups')
        expect(page).to have_link('Contributed projects')
        expect(page).to have_link('Personal projects')
        expect(page).to have_link('Snippets')
      end
    end
  end

  it 'shows the status if there was one' do
    create(:user_status, user: user, message: "Working hard!")

    visit(user_path(user))

    expect(page).to have_content("Working hard!")
  end

  context 'signup disabled' do
    it 'shows the sign in link' do
      stub_application_setting(signup_enabled: false)

      visit(user_path(user))

      page.within '.navbar-nav' do
        expect(page).to have_link('Sign in')
      end
    end
  end

  context 'signup enabled' do
    it 'shows the sign in and register link' do
      stub_application_setting(signup_enabled: true)

      visit(user_path(user))

      page.within '.navbar-nav' do
        expect(page).to have_link('Sign in / Register')
      end
    end
  end
end
