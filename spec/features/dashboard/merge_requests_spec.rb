require 'spec_helper'

describe 'Dashboard Merge Requests' do
  let(:current_user) { create :user }
  let(:project) do
    create(:empty_project) do |project|
      project.add_master(current_user)
    end
  end

  before do
    login_as(current_user)
  end

  it 'should show an empty state' do
    visit merge_requests_dashboard_path(assignee_id: current_user.id)

    expect(page).to have_selector('.empty-state')
  end

  context 'if there are merge requests' do
    before do
      create(:merge_request, assignee: current_user, source_project: project)

      visit merge_requests_dashboard_path(assignee_id: current_user.id)
    end

    it 'should not show an empty state' do
      expect(page).not_to have_selector('.empty-state')
    end
  end
end
