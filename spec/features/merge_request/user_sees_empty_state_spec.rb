require 'rails_helper'

describe 'Merge request > User sees empty state' do
  let(:project) { create(:project, :public, :repository) }
  let(:user)    { project.creator }

  before do
    project.add_master(user)
    sign_in(user)
  end

  it 'shows an empty state and a "New merge request" button' do
    visit project_merge_requests_path(project)

    expect(page).to have_selector('.empty-state')
    expect(page).to have_link 'New merge request', href: project_new_merge_request_path(project)
  end

  context 'if there are merge requests' do
    before do
      create(:merge_request, source_project: project)

      visit project_merge_requests_path(project)
    end

    it 'does not show an empty state' do
      expect(page).not_to have_selector('.empty-state')
    end
  end
end
