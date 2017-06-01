require 'spec_helper'

describe 'Dashboard Merge Requests' do
  let(:current_user) { create :user }
  let(:project) { create(:empty_project) }
  let(:project_with_merge_requests_disabled) { create(:empty_project, :merge_requests_disabled) }

  before do
    [project, project_with_merge_requests_disabled].each { |project| project.team << [current_user, :master] }

    login_as(current_user)
  end

  describe 'new merge request dropdown' do
    before { visit merge_requests_dashboard_path }

    it 'shows projects only with merge requests feature enabled', js: true do
      find('.new-project-item-select-button').trigger('click')

      page.within('.select2-results') do
        expect(page).to have_content(project.name_with_namespace)
        expect(page).not_to have_content(project_with_merge_requests_disabled.name_with_namespace)
      end
    end
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
