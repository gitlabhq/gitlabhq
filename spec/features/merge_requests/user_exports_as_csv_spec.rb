# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Requests > Exports as CSV', :js, feature_category: :code_review_workflow do
  let!(:project) { create(:project, :public, :repository) }
  let!(:user)    { project.creator }
  let!(:open_mr) { create(:merge_request, title: 'Bugfix1', source_project: project, target_project: project, source_branch: 'bugfix1') }

  before do
    sign_in(user)
  end

  def open_export_modal
    visit(project_merge_requests_path(project))
    click_button 'Actions'
    click_button 'Export as CSV'
  end

  context 'button is clicked' do
    before do
      open_export_modal
    end

    it 'shows a success message' do
      click_button('Export merge requests')

      expect(page).to have_content 'Your CSV export request has succeeded. ' \
        "The result will be emailed to #{user.notification_email_or_default}."
    end
  end

  context 'when the merge_requests_csv_export_graphql feature flag is disabled' do
    before do
      stub_feature_flags(merge_requests_csv_export_graphql: false)
      open_export_modal
    end

    it 'shows a success message' do
      click_link('Export merge requests')

      expect(page).to have_content 'Your CSV export has started.'
      expect(page).to have_content "It will be emailed to #{user.email} when complete"
    end
  end
end
