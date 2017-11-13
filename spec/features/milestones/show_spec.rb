require 'rails_helper'

describe 'Milestone show' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:milestone) { create(:milestone, project: project) }
  let(:labels) { create_list(:label, 2, project: project) }
  let(:issue_params) { { project: project, assignees: [user], author: user, milestone: milestone, labels: labels } }

  before do
    project.add_user(user, :developer)
    sign_in(user)
  end

  def visit_milestone
    visit project_milestone_path(project, milestone)
  end

  it 'avoids N+1 database queries' do
    create(:labeled_issue, issue_params)
    control = ActiveRecord::QueryRecorder.new { visit_milestone }
    create_list(:labeled_issue, 10, issue_params)

    expect { visit_milestone }.not_to exceed_query_limit(control)
  end
end
