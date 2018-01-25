require 'rails_helper'

describe 'Merge request > User sees deleted target branch', :js do
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }
  let(:user) { project.creator }

  before do
    project.add_master(user)
    DeleteBranchService.new(project, user).execute('feature')
    sign_in(user)
    visit project_merge_request_path(project, merge_request)
  end

  it 'shows a message about missing target branch' do
    expect(page).to have_content('Target branch does not exist')
  end

  it 'does not show link to target branch' do
    expect(page).not_to have_selector('.mr-widget-body .js-branch-text a')
  end
end
