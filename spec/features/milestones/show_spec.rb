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
    let(:issue_params) { { project: project, assignee: user, author: user, milestone: milestone } }

    context 'when any closed issues do not have closed_at value' do
      it 'shows warning' do
        create(:issue, issue_params)
        create(:closed_issue, issue_params)
        create(:closed_issue, issue_params.merge(closed_at: nil))

        visit_milestone

        expect(page).to have_selector('#data-warning', count: 1)
        expect(page.find('#data-warning').text).to include("Some issues can’t be shown in the burndown chart")
        expect(page).to have_selector('.burndown-chart')
      end
    end

    context 'when all closed issues do not have closed_at value' do
      it 'shows warning and hides burndown' do
        create(:closed_issue, issue_params.merge(closed_at: nil))
        create(:closed_issue, issue_params.merge(closed_at: nil))

        visit_milestone

        expect(page).to have_selector('#data-warning', count: 1)
        expect(page.find('#data-warning').text).to include("The burndown chart can’t be shown")
        expect(page).not_to have_selector('.burndown-chart')
      end
    end

    context 'data is accurate' do
      it 'does not show warning' do
        create(:issue, issue_params)
        create(:closed_issue, issue_params)

        visit_milestone

        expect(page).not_to have_selector('#data-warning')
        expect(page).to have_selector('.burndown-chart')
      end
    end
  end
end
