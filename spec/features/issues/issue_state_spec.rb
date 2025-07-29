# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'issue state', :js, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }

  before do
    stub_feature_flags(work_item_view_for_issues: true)
    project.add_developer(user)
    sign_in(user)
  end

  shared_examples 'issue closed' do |selector|
    it 'closes an issue' do
      expect(page).to have_css('.gl-badge', text: 'Open')

      within_testid(selector) do
        click_button 'Close issue'
      end

      expect(page).to have_css('.gl-badge', text: 'Closed')
    end
  end

  shared_examples 'issue reopened' do |selector|
    it 'reopens an issue' do
      expect(page).to have_css('.gl-badge', text: 'Closed')

      within_testid(selector) do
        click_button 'Reopen issue'
      end

      expect(page).to have_css('.gl-badge', text: 'Open')
    end
  end

  describe 'when open' do
    context 'when clicking the top `Close issue` button', :aggregate_failures do
      let(:open_issue) { create(:issue, project: project) }

      before do
        visit project_issue_path(project, open_issue)
        click_button 'More actions', match: :first
      end

      it_behaves_like 'issue closed', 'work-item-actions-dropdown'
    end

    context 'when clicking the bottom `Close issue` button', :aggregate_failures do
      let(:open_issue) { create(:issue, project: project) }

      before do
        visit project_issue_path(project, open_issue)
      end

      it_behaves_like 'issue closed', 'work-item-comment-form-actions'
    end
  end

  describe 'when closed' do
    context 'when clicking the top `Reopen issue` button', :aggregate_failures do
      let(:closed_issue) { create(:issue, project: project, state: 'closed', author: user) }

      before do
        visit project_issue_path(project, closed_issue)
        click_button 'More actions', match: :first
      end

      it_behaves_like 'issue reopened', 'work-item-actions-dropdown'
    end

    context 'when clicking the bottom `Reopen issue` button', :aggregate_failures do
      let(:closed_issue) { create(:issue, project: project, state: 'closed') }

      before do
        visit project_issue_path(project, closed_issue)
      end

      it_behaves_like 'issue reopened', 'work-item-comment-form-actions'
    end
  end
end
