# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New issue breadcrumb', :js, feature_category: :team_planning do
  let_it_be(:project, reload: true) { create(:project) }

  let(:user) { project.creator }

  before do
    sign_in(user)
    visit(new_project_issue_path(project))
  end

  it 'displays link to project issues and new issue' do
    within_testid 'breadcrumb-links' do
      expect(find_link('Issues')[:href]).to end_with(project_issues_path(project))
      expect(find_link('New')[:href]).to end_with(new_project_issue_path(project))
    end
  end

  it 'links to current issue in breadcrumbs' do
    issue = create(:issue, project: project)

    visit project_issue_path(project, issue)

    within_testid 'breadcrumb-links' do
      expect(find('.gl-breadcrumb-item:last-of-type a')[:href]).to end_with(issue_path(issue))
    end
  end

  it 'excludes award_emoji from comment count' do
    issue = create(:issue, author: user, assignees: [user], project: project, title: 'foobar')
    create(:award_emoji, awardable: issue)

    visit project_issues_path(project, assignee_id: user.id)

    expect(page).to have_content 'foobar'
    expect(page).not_to have_selector("[data-testid='issuable-comments']")
  end
end
