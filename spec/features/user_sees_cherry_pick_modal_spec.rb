require 'rails_helper'

describe 'Merge request > User sees cherry-pick modal', :js do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    sign_in(user)
    visit(project_merge_request_path(project, merge_request))
    click_button('Merge')
    visit(merge_request_path(merge_request))
    click_link('Cherry-pick')
  end

  it 'shows the cherry-pick modal' do
    expect(page).to have_content('Cherry-pick this merge request')
  end

  it 'closes the cherry-pick modal with escape keypress' do
    find('#modal-cherry-pick-commit').send_keys(:escape)

    expect(page).not_to have_content('Start a new merge request with these changes')
  end
end
