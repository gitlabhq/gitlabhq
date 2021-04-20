# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Users > Terms' do
  include TermsHelper

  let!(:term) { create(:term, terms: 'By accepting, you promise to be nice!') }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  it 'shows the terms' do
    visit terms_path

    expect(page).to have_content('By accepting, you promise to be nice!')
  end

  it 'does not show buttons to accept, decline or sign out', :aggregate_failures do
    visit terms_path

    expect(page).not_to have_css('.footer-block')
    expect(page).not_to have_content('Accept terms')
    expect(page).not_to have_content('Decline and sign out')
    expect(page).not_to have_content('Continue')
  end

  context 'when user is a project bot' do
    let(:project_bot) { create(:user, :project_bot) }

    before do
      enforce_terms
    end

    it 'auto accepts the terms' do
      visit terms_path

      expect(page).not_to have_content('Accept terms')
      expect(project_bot.terms_accepted?).to be(true)
    end
  end

  context 'when signed in' do
    let(:user) { create(:user) }

    before do
      sign_in(user)
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

    context 'when the user has already accepted the terms' do
      before do
        accept_terms(user)
      end

      it 'allows the user to continue to the app' do
        visit terms_path

        expect(page).to have_content "You have already accepted the Terms of Service as #{user.to_reference}"

        click_link 'Continue'

        expect(current_path).to eq(root_path)
      end
    end

    context 'terms were enforced while session is active', :js do
      let(:project) { create(:project) }

      before do
        project.add_developer(user)
      end

      it 'redirects to terms and back to where the user was going' do
        visit project_path(project)

        enforce_terms

        # Application settings are cached for a minute
        Timecop.travel 2.minutes do
          within('.nav-sidebar') do
            click_link 'Issues'
          end

          expect_to_be_on_terms_page

          click_button('Accept terms')

          expect(current_path).to eq(project_issues_path(project))
        end
      end

      # Disabled until https://gitlab.com/gitlab-org/gitlab-foss/issues/37162 is solved properly
      xit 'redirects back to the page the user was trying to save' do
        visit new_project_issue_path(project)

        fill_in :issue_title, with: 'Hello world, a new issue'
        fill_in :issue_description, with: "We don't want to lose what the user typed"

        enforce_terms

        click_button 'Create issue'

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
end
