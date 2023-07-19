# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Activity > User sees activity', feature_category: :groups_and_projects do
  let(:project) { create(:project, :repository, :public) }
  let(:user) { project.creator }
  let(:issue) { create(:issue, project: project) }

  before do
    create(:event, :created, project: project, target: issue, author: user)
    event = create(:push_event, project: project, author: user)
    create(
      :push_event_payload,
      event: event,
      action: :created,
      commit_to: '6d394385cf567f80a8fd85055db1ab4c5295806f',
      ref: 'fix',
      commit_count: 1
    )
  end

  it 'shows the last push in the activity page', :js do
    visit activity_project_path(project)

    expect(page).to have_content "#{user.name} #{user.to_reference} pushed new branch fix"
  end

  it 'allows to filter event with the "event_filter=issue" URL param', :js do
    visit activity_project_path(project, event_filter: 'issue')

    expect(page).not_to have_content "#{user.name} #{user.to_reference} pushed new branch fix"
    expect(page).to have_content "#{user.name} #{user.to_reference} opened issue #{issue.to_reference}"
  end
end
