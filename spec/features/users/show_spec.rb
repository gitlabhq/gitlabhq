require 'spec_helper'

describe 'User page' do
  let(:user) { create(:user) }

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
