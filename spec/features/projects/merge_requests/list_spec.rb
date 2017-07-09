require 'spec_helper'

feature 'Merge Requests List' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  background do
    project.team << [user, :developer]

    sign_in(user)
  end

  scenario 'user does not see create new list button' do
    create(:merge_request, source_project: project)

    visit project_merge_requests_path(project)

    expect(page).not_to have_selector('.js-new-board-list')
  end

  it 'should show an empty state' do
    visit project_merge_requests_path(project)

    expect(page).to have_selector('.empty-state')
  end

  it 'empty state should have a create merge request button' do
    visit project_merge_requests_path(project)

    expect(page).to have_link 'New merge request', href: project_new_merge_request_path(project)
  end

  context 'if there are merge requests' do
    before do
      create(:merge_request, assignee: user, source_project: project)

      visit project_merge_requests_path(project)
    end

    it 'should not show an empty state' do
      expect(page).not_to have_selector('.empty-state')
    end
  end
end
