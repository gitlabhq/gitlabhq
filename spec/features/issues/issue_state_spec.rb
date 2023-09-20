# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'issue state', :js, feature_category: :team_planning do
  include CookieHelper

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_developer(user)
    sign_in(user)
    set_cookie('new-actions-popover-viewed', 'true')
  end

  shared_examples 'issue closed' do |selector|
    it 'can close an issue' do
      expect(page).to have_selector('[data-testid="issue-state-badge"]')

      expect(find('[data-testid="issue-state-badge"]')).to have_content 'Open'

      within selector do
        click_button 'Close issue'
        wait_for_requests
      end

      expect(find('[data-testid="issue-state-badge"]')).to have_content 'Closed'
    end
  end

  shared_examples 'issue reopened' do |selector|
    it 'can reopen an issue' do
      expect(page).to have_selector('[data-testid="issue-state-badge"]')

      expect(find('[data-testid="issue-state-badge"]')).to have_content 'Closed'

      within selector do
        click_button 'Reopen issue'
        wait_for_requests
      end

      expect(find('[data-testid="issue-state-badge"]')).to have_content 'Open'
    end
  end

  describe 'when open' do
    context 'when clicking the top `Close issue` button', :aggregate_failures do
      context 'when move_close_into_dropdown FF is disabled' do
        let(:open_issue) { create(:issue, project: project) }

        before do
          stub_feature_flags(move_close_into_dropdown: false)
          visit project_issue_path(project, open_issue)
        end

        it_behaves_like 'issue closed', '.detail-page-header-actions'
      end

      context 'when move_close_into_dropdown FF is enabled' do
        let(:open_issue) { create(:issue, project: project) }

        before do
          visit project_issue_path(project, open_issue)
          find('#new-actions-header-dropdown > button').click
        end

        it_behaves_like 'issue closed', '.dropdown-menu-right'
      end
    end

    context 'when clicking the bottom `Close issue` button', :aggregate_failures do
      let(:open_issue) { create(:issue, project: project) }

      before do
        visit project_issue_path(project, open_issue)
      end

      it_behaves_like 'issue closed', '.timeline-content-form'
    end
  end

  describe 'when closed' do
    context 'when clicking the top `Reopen issue` button', :aggregate_failures do
      context 'when move_close_into_dropdown FF is disabled' do
        let(:closed_issue) { create(:issue, project: project, state: 'closed', author: user) }

        before do
          stub_feature_flags(move_close_into_dropdown: false)
          visit project_issue_path(project, closed_issue)
        end

        it_behaves_like 'issue reopened', '.detail-page-header-actions'
      end

      context 'when move_close_into_dropdown FF is enabled' do
        let(:closed_issue) { create(:issue, project: project, state: 'closed', author: user) }

        before do
          visit project_issue_path(project, closed_issue)
          find('#new-actions-header-dropdown > button').click
        end

        it_behaves_like 'issue reopened', '.dropdown-menu-right'
      end
    end

    context 'when clicking the bottom `Reopen issue` button', :aggregate_failures do
      let(:closed_issue) { create(:issue, project: project, state: 'closed') }

      before do
        visit project_issue_path(project, closed_issue)
      end

      it_behaves_like 'issue reopened', '.timeline-content-form'
    end
  end
end
