# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Activity > User sees design comment', :js, feature_category: :design_management do
  include DesignManagementTestHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:user) { project.creator }
  let_it_be(:commenter) { create(:user) }
  let_it_be(:issue) { create(:closed_issue, project: project) }
  let_it_be(:design) { create(:design, issue: issue) }

  let(:design_activity) do
    "#{commenter.name} #{commenter.to_reference} commented on design #{design.to_reference}"
  end

  let(:issue_activity) do
    "#{user.name} #{user.to_reference} closed issue #{issue.to_reference}"
  end

  before_all do
    project.add_developer(commenter)
    create(:event, :for_design, project: project, author: commenter, design: design)
    create(:closed_issue_event, project: project, author: user, target: issue)
  end

  before do
    enable_design_management
  end

  it 'shows the design comment action in the activity page' do
    visit activity_project_path(project)

    expect(page).to have_content(design_activity)
  end

  it 'allows to filter out the design event with the "event_filter=issue" URL param', :aggregate_failures do
    visit activity_project_path(project, event_filter: EventFilter::ISSUE)

    expect(page).not_to have_content(design_activity)
    expect(page).to have_content(issue_activity)
  end

  it 'allows to filter in the event with the "event_filter=comments" URL param', :aggregate_failures do
    visit activity_project_path(project, event_filter: EventFilter::COMMENTS)

    expect(page).to have_content(design_activity)
    expect(page).not_to have_content(issue_activity)
  end
end
