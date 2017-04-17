require 'rails_helper'

describe 'Milestone show', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }
  let(:milestone) { create(:milestone, project: project, start_date: Date.today, due_date: 7.days.from_now) }
  let(:labels) { create_list(:label, 2, project: project) }
  let(:issue_params) { { project: project, assignee: user, author: user, milestone: milestone, labels: labels } }

  before do
    project.add_user(user, :developer)
    login_as(user)
  end

  def visit_milestone
    visit namespace_project_milestone_path(project.namespace, project, milestone)
  end

  it 'avoids N+1 database queries' do
    create(:labeled_issue, issue_params)
    control_count = ActiveRecord::QueryRecorder.new { visit_milestone }.count
    create_list(:labeled_issue, 10, issue_params)

    expect { visit_milestone }.not_to exceed_query_limit(control_count)
  end

  context 'burndown' do
    before { issue_params.delete(:labels) }

    context 'when closed issues does not have closed_at value' do
      it 'shows warning' do
        create(:issue, issue_params)
        issue = create(:issue, issue_params)
        issue.update(state: 'closed')
        issue.update(closed_at: nil)

        visit_milestone

        expect(page).to have_selector('#no-data-warning')
      end
    end

    context 'data is accurate' do
      it 'does not show warning' do
        create(:issue, issue_params)
        issue = create(:issue, issue_params)
        issue.close

        visit_milestone

        expect(page).not_to have_selector('#no-data-warning')
      end
    end
  end
end
