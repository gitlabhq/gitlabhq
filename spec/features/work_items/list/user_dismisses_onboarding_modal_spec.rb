# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User dismisses work items onboarding modal', :js, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  before_all do
    project.add_developer(user)
  end

  before do
    sign_in(user)
    visit project_work_items_path(project)
    wait_for_requests
  end

  context 'when user has not dismissed the modal before' do
    it 'shows the onboarding modal on first visit' do
      expect(page).to have_css('[data-testid="work-items-onboarding-modal"]')
    end

    it 'dismisses modal when clicking the close icon and does not show again' do
      within_testid('work-items-onboarding-modal') do
        find_by_testid('close-icon').click
      end

      expect(page).not_to have_css('[data-testid="work-items-onboarding-modal"]')

      page.refresh
      wait_for_requests

      expect(page).not_to have_css('[data-testid="work-items-onboarding-modal"]')
    end
  end

  context 'when user has already dismissed the modal' do
    before_all do
      create(:callout, user: user, feature_name: :work_items_onboarding_modal)
    end
    it 'does not show the onboarding modal' do
      expect(page).not_to have_css('[data-testid="work-items-onboarding-modal"]')
    end
  end
end
