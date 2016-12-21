require 'rails_helper'

describe 'Milestone show', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }
  let(:milestone) { create(:milestone, project: project) }
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
end
