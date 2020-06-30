# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User design permissions', :js do
  include DesignManagementTestHelpers

  let(:project) { create(:project_empty_repo, :public) }
  let(:issue) { create(:issue, project: project) }

  context 'design_management_moved flag disabled' do
    before do
      enable_design_management
      stub_feature_flags(design_management_moved: false)

      visit project_issue_path(project, issue)

      click_link 'Designs'

      wait_for_requests
    end

    it 'user does not have permissions to upload design' do
      expect(page).not_to have_field('design_file')
    end
  end

  context 'design_management_moved flag enabled' do
    before do
      enable_design_management

      visit project_issue_path(project, issue)
    end

    it 'user does not have permissions to upload design' do
      expect(page).not_to have_field('design_file')
    end
  end
end
