# frozen_string_literal: true

require 'spec_helper'

describe 'User uploads new design', :js do
  include DesignManagementTestHelpers

  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:user) { project.owner }
  let_it_be(:issue) { create(:issue, project: project) }

  before do
    sign_in(user)
  end

  context "when the feature is available" do
    before do
      enable_design_management

      visit project_issue_path(project, issue)

      click_link 'Designs'

      wait_for_requests
    end

    it 'uploads designs' do
      attach_file(:design_file, logo_fixture, make_visible: true)

      expect(page).to have_selector('.js-design-list-item', count: 1)

      within first('#designs-tab .js-design-list-item') do
        expect(page).to have_content('dk.png')
      end

      attach_file(:design_file, gif_fixture, make_visible: true)

      expect(page).to have_selector('.js-design-list-item', count: 2)
    end
  end

  context 'when the feature is not available' do
    before do
      visit project_issue_path(project, issue)

      click_link 'Designs'

      wait_for_requests
    end

    it 'shows the message about requirements' do
      expect(page).to have_content("To enable design management, you'll need to meet the requirements.")
    end
  end

  def logo_fixture
    Rails.root.join('spec', 'fixtures', 'dk.png')
  end

  def gif_fixture
    Rails.root.join('spec', 'fixtures', 'banana_sample.gif')
  end
end
