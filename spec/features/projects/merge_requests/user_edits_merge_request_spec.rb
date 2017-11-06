require 'spec_helper'

describe 'User edits a merge request', :js do
  include Select2Helper

  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(edit_project_merge_request_path(project, merge_request))
  end

  it 'changes the target branch' do
    expect(page).to have_content('Target branch')

    select2('merge-test', from: '#merge_request_target_branch')
    click_button('Save changes')

    expect(page).to have_content("Request to merge #{merge_request.source_branch} into merge-test")
    expect(page).to have_content("changed target branch from #{merge_request.target_branch} to merge-test")
  end
end
