# frozen_string_literal: true

require "spec_helper"

RSpec.describe 'User sees experimental lmarketing header' do
  let_it_be(:project) { create(:project, :public) }

  context 'when not logged in' do
    context 'when experiment candidate' do
      it 'shows marketing header links', :aggregate_failures do
        stub_experiments(logged_out_marketing_header: :candidate)

        visit project_path(project)

        expect(page).to have_text "About GitLab"
        expect(page).to have_text "Pricing"
        expect(page).to have_text "Talk to an expert"
        expect(page).to have_text "Sign up now"
        expect(page).to have_text "Login"
      end
    end

    context 'when experiment control' do
      it 'does not show marketing header links', :aggregate_failures do
        stub_experiments(logged_out_marketing_header: :control)

        visit project_path(project)

        expect(page).not_to have_text "About GitLab"
        expect(page).not_to have_text "Pricing"
        expect(page).not_to have_text "Talk to an expert"
        expect(page).not_to have_text "Sign up now"
        expect(page).not_to have_text "Login"
        expect(page).to have_text "Sign in / Register"
      end
    end
  end

  context 'when logged in' do
    it 'does not show marketing header links', :aggregate_failures do
      sign_in(create(:user))

      stub_experiments(logged_out_marketing_header: :candidate)

      visit project_path(project)

      expect(page).not_to have_text "About GitLab"
      expect(page).not_to have_text "Pricing"
      expect(page).not_to have_text "Talk to an expert"
    end
  end
end
