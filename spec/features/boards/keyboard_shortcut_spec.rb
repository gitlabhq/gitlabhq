# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue Boards shortcut', :js, feature_category: :portfolio_management do
  context 'issues are enabled' do
    let(:project) { create(:project) }

    before do
      create(:board, project: project)

      admin = create(:admin)
      sign_in(admin)
      enable_admin_mode!(admin)

      visit project_path(project)
    end

    it 'takes user to issue board index' do
      find('body').native.send_keys('gb')
      expect(page).to have_selector('.boards-list')

      wait_for_requests
    end
  end

  context 'issues are not enabled' do
    let(:project) { create(:project, :issues_disabled) }

    before do
      admin = create(:admin)
      sign_in(admin)
      enable_admin_mode!(admin)

      visit project_path(project)
    end

    it 'does not take user to the issue board index' do
      find('body').native.send_keys('gb')

      expect(page).to have_selector("body[data-page='projects:show']")
    end
  end
end
