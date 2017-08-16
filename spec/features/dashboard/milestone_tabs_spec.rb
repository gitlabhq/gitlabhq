require 'spec_helper'

describe 'Dashboard milestone tabs', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let!(:label) { create(:label, project: project) }
  let(:project_milestone) { create(:milestone, project: project) }
  let(:milestone) do
    DashboardMilestone.build(
      [project],
      project_milestone.title
    )
  end
  let!(:merge_request) { create(:labeled_merge_request, source_project: project, target_project: project, milestone: project_milestone, labels: [label]) }

  before do
    project.add_master(user)
    sign_in(user)

    visit dashboard_milestone_path(milestone.safe_title, title: milestone.title)
  end

  it 'loads merge requests async' do
    click_link 'Merge Requests'

    expect(page).to have_selector('.milestone-merge_requests-list')
  end

  it 'loads participants async' do
    click_link 'Participants'

    expect(page).to have_selector('#tab-participants .bordered-list')
  end

  it 'loads labels async' do
    click_link 'Labels'

    expect(page).to have_selector('#tab-labels .bordered-list')
  end
end
