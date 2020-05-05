# frozen_string_literal: true

require 'spec_helper'

describe "User views milestone" do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:labels) { create_list(:label, 2, project: project) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  it "avoids N+1 database queries" do
    issue_params = { project: project, assignees: [user], author: user, milestone: milestone, labels: labels }.freeze

    create(:labeled_issue, issue_params)

    control = ActiveRecord::QueryRecorder.new { visit_milestone }

    create(:labeled_issue, issue_params)

    expect { visit_milestone }.not_to exceed_query_limit(control)
  end

  context 'limiting milestone issues' do
    before_all do
      2.times do
        create(:issue, milestone: milestone, project: project)
        create(:issue, milestone: milestone, project: project, assignees: [user])
        create(:issue, milestone: milestone, project: project, state: :closed)
      end
    end

    context 'when issues on milestone are over DISPLAY_ISSUES_LIMIT' do
      it "limits issues to display and shows warning" do
        stub_const('Milestoneish::DISPLAY_ISSUES_LIMIT', 3)

        visit(project_milestone_path(project, milestone))

        expect(page).to have_selector('.issuable-row', count: 3)
        expect(page).to have_selector('#milestone-issue-count-warning', text: 'Showing 3 of 6 issues. View all issues')
        expect(page).to have_link('View all issues', href: project_issues_path(project, { milestone_title: milestone.title }))
      end
    end

    context 'when issues on milestone are below DISPLAY_ISSUES_LIMIT' do
      it 'does not display warning' do
        visit(project_milestone_path(project, milestone))

        expect(page).not_to have_selector('#milestone-issue-count-warning', text: 'Showing 3 of 6 issues. View all issues')
        expect(page).to have_selector('.issuable-row', count: 6)
      end
    end
  end

  private

  def visit_milestone
    visit(project_milestone_path(project, milestone))
  end
end
