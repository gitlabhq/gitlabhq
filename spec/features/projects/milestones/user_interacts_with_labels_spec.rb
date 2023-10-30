# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User interacts with labels', feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let(:milestone) { create(:milestone, project: project, title: 'v2.2', description: '# Description header') }
  let(:issue1) { create(:issue, project: project, title: 'Bugfix1', milestone: milestone) }
  let(:issue2) { create(:issue, project: project, title: 'Bugfix2', milestone: milestone) }
  let(:label_bug) { create(:label, project: project, title: 'bug') }
  let(:label_feature) { create(:label, project: project, title: 'feature') }
  let(:label_enhancement) { create(:label, project: project, title: 'enhancement') }

  before do
    project.add_maintainer(user)
    sign_in(user)

    issue1.labels << [label_bug, label_feature]
    issue2.labels << [label_bug, label_enhancement]

    visit(project_milestones_path(project))
  end

  it 'shows the list of labels', :js do
    click_link('v2.2')

    page.find(:xpath, "//a[@href='#tab-labels']").click

    expect(page).to have_selector('ul.manage-labels-list')

    wait_for_requests

    page.within('#tab-labels') do
      expect(page).to have_content(label_bug.title)
      expect(page).to have_content(label_enhancement.title)
      expect(page).to have_content(label_feature.title)
    end
  end
end
