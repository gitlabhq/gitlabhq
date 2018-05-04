require "rails_helper"

describe "User views milestone" do
  set(:user) { create(:user) }
  set(:project) { create(:project) }
  set(:milestone) { create(:milestone, project: project) }
  set(:labels) { create_list(:label, 2, project: project) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  it "avoids N+1 database queries" do
    ISSUE_PARAMS = { project: project, assignees: [user], author: user, milestone: milestone, labels: labels }.freeze

    create(:labeled_issue, ISSUE_PARAMS)

    control = ActiveRecord::QueryRecorder.new { visit_milestone }

    create(:labeled_issue, ISSUE_PARAMS)

    expect { visit_milestone }.not_to exceed_query_limit(control)
  end

  private

  def visit_milestone
    visit(project_milestone_path(project, milestone))
  end
end
