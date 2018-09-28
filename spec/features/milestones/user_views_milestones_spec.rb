require "rails_helper"

describe "User views milestones" do
  set(:user) { create(:user) }
  set(:project) { create(:project) }
  set(:milestone) { create(:milestone, project: project) }

  before do
    project.add_developer(user)
    sign_in(user)

    visit(project_milestones_path(project))
  end

  it "shows milestone" do
    expect(page).to have_content(milestone.title)
      .and have_content(milestone.expires_at)
      .and have_content("Issues")
  end

  context "with issues" do
    set(:issue) { create(:issue, project: project, milestone: milestone) }
    set(:closed_issue) { create(:closed_issue, project: project, milestone: milestone) }

    it "opens milestone" do
      click_link(milestone.title)

      expect(current_path).to eq(project_milestone_path(project, milestone))
      expect(page).to have_content(milestone.title)
        .and have_selector("#tab-issues li.issuable-row", count: 2)
        .and have_content(issue.title)
        .and have_content(closed_issue.title)
    end
  end
end
