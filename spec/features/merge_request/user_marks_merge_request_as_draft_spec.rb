# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User marks merge request as draft', :js, feature_category: :code_review_workflow do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    project.add_maintainer(user)

    sign_in(user)

    visit project_merge_request_path(project, merge_request)
  end

  it 'toggles draft status' do
    find('#new-actions-header-dropdown button').click
    click_button 'Mark as draft'

    expect(page).to have_content("Draft: #{merge_request.title}")

    find('#new-actions-header-dropdown button').click

    page.within('.detail-page-header-actions') do
      click_button 'Mark as ready'
    end

    expect(page).to have_content(merge_request.title)
  end
end
