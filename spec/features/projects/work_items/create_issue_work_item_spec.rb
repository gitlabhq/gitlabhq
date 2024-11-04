# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create issuable work item', :js, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, developers: user) }

  context 'when we go to new work item path in project and select issue from dropdown' do
    before do
      sign_in(user)
      visit "#{project_path(project)}/-/work_items/new"
      select 'Issue', from: 'Type'
    end

    it 'has the expected widgets', :aggregate_failures do
      expect(page).to have_selector('[data-testid="work-item-title-input"]')
      expect(page).to have_selector('[data-testid="work-item-labels"]')
      expect(page).to have_selector('[data-testid="work-item-assignees"]')
      expect(page).to have_selector('[data-testid="work-item-description-wrapper"]')
      expect(page).to have_selector('[data-testid="work-item-milestone"]')
    end
  end
end
