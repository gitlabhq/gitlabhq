# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create issue work item', :js, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, developers: user) }

  context 'when on new work items page' do
    before do
      sign_in(user)
      visit "#{project_path(project)}/-/work_items/new"
    end

    context 'when "Issue" is selected from drop down' do
      before do
        select 'Issue', from: 'Type'
      end

      it 'creates an issue work item', :aggregate_failures do
        # check all the widgets are rendered
        expect(page).to have_selector('[data-testid="work-item-title-input"]')
        expect(page).to have_selector('[data-testid="work-item-description-wrapper"]')
        expect(page).to have_selector('[data-testid="work-item-assignees"]')
        expect(page).to have_selector('[data-testid="work-item-labels"]')
        expect(page).to have_selector('[data-testid="work-item-milestone"]')
        expect(page).to have_selector('[data-testid="work-item-parent"]')

        send_keys 'I am a new issue'
        click_button 'Create issue'

        expect(page).to have_css('h1', text: 'I am a new issue')
        expect(page).to have_text 'Issue created'
      end
    end
  end
end
