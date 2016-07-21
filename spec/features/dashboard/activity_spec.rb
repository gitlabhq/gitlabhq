require 'spec_helper'

describe 'Dashboard activity', feature: true, js: true do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }
  let!(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: user) }
  let!(:merge_event) { create(:event, action: Event::CREATED, project: project, target: merge_request, author: user) }

  before do
    project.team << [user, :master]
    login_as(user)

    visit activity_dashboard_path
  end

  it 'defaults to filtering by all' do
    expect(page).to have_selector('.event-item', count: 2)
  end

  it 'filters by all' do
    page.within '.event-filter' do
      click_link 'Merge events'
    end
    expect(page).to have_selector('.event-item', count: 0)

    page.within '.event-filter' do
      click_link 'All'
    end
    expect(page).to have_selector('.event-item', count: 2)
  end

  it 'filters by merge requests' do
    page.within '.event-filter' do
      click_link 'Merge events'
    end

    expect(page).to have_selector('.event-item', count: 0)
  end
end
