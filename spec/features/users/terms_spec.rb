require 'spec_helper'

describe 'Users > Terms' do
  include TermsHelper

  let(:user) { create(:user) }
  let!(:term) { create(:term, terms: 'By accepting, you promise to be nice!') }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(user)
  end

  it 'shows the terms' do
    visit terms_path

    expect(page).to have_content('By accepting, you promise to be nice!')
  end

  context 'declining the terms' do
    it 'returns the user to the app' do
      visit terms_path

      click_button 'Decline and sign out'

      expect(page).not_to have_content(term.terms)
      expect(user.reload.terms_accepted?).to be(false)
    end
  end

  context 'accepting the terms' do
    it 'returns the user to the app' do
      visit terms_path

      click_button 'Accept terms'

      expect(page).not_to have_content(term.terms)
      expect(user.reload.terms_accepted?).to be(true)
    end
  end

  context 'terms were enforced while session is active', :js do
    let(:project) { create(:project) }

    before do
      project.add_developer(user)
    end

    it 'redirects to terms and back to where the user was going'  do
      visit project_path(project)

      enforce_terms

      within('.nav-sidebar') do
        click_link 'Issues'
      end

      expect_to_be_on_terms_page

      click_button('Accept terms')

      expect(current_path).to eq(project_issues_path(project))
    end

    # Disabled until https://gitlab.com/gitlab-org/gitlab-ce/issues/37162 is solved properly
    xit 'redirects back to the page the user was trying to save' do
      visit new_project_issue_path(project)

      fill_in :issue_title, with: 'Hello world, a new issue'
      fill_in :issue_description, with: "We don't want to lose what the user typed"

      enforce_terms

      click_button 'Submit issue'

      expect(current_path).to eq(terms_path)

      click_button('Accept terms')

      expect(current_path).to eq(new_project_issue_path(project))
      expect(find_field('issue_title').value).to eq('Hello world, a new issue')
      expect(find_field('issue_description').value).to eq("We don't want to lose what the user typed")
    end
  end

  context 'when the terms are enforced' do
    before do
      enforce_terms
    end

    context 'signing out', :js do
      it 'allows the user to sign out without a response' do
        visit terms_path

        find('.header-user-dropdown-toggle').click
        click_link('Sign out')

        expect(page).to have_content('Sign in')
        expect(page).to have_content('Register')
      end
    end
  end
end
