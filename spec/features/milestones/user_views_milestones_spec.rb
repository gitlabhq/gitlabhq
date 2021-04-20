# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "User views milestones" do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:milestone) { create(:milestone, project: project) }

  before do
    project.add_developer(user)
    sign_in(user)

    visit(project_milestones_path(project))
  end

  it "shows milestone" do
    expect(page).to have_content(milestone.title)
      .and have_content(milestone.expires_at)
      .and have_content("Issues")
      .and have_content("Merge requests")
  end

  context "with issues", :js do
    let_it_be(:issue) { create(:issue, project: project, milestone: milestone) }
    let_it_be(:closed_issue) { create(:closed_issue, project: project, milestone: milestone) }

    it "opens milestone" do
      click_link(milestone.title)

      expect(current_path).to eq(project_milestone_path(project, milestone))
      expect(page).to have_content(milestone.title)
        .and have_selector("#tab-issues li.issuable-row", count: 2)
        .and have_content(issue.title)
        .and have_content(closed_issue.title)
    end
  end

  context "with associated releases" do
    let_it_be(:first_release) { create(:release, project: project, name: "The first release", milestones: [milestone], released_at: Time.zone.parse('2019-10-07')) }

    context "with a single associated release" do
      it "shows the associated release" do
        expect(page).to have_content("Release #{first_release.name}")
        expect(page).to have_link(first_release.name, href: project_releases_path(project, anchor: first_release.tag))
      end
    end

    context "with lots of associated releases" do
      let_it_be(:second_release) { create(:release, project: project, name: "The second release", milestones: [milestone], released_at: first_release.released_at + 1.day) }
      let_it_be(:third_release) { create(:release, project: project, name: "The third release", milestones: [milestone], released_at: second_release.released_at + 1.day) }
      let_it_be(:fourth_release) { create(:release, project: project, name: "The fourth release", milestones: [milestone], released_at: third_release.released_at + 1.day) }
      let_it_be(:fifth_release) { create(:release, project: project, name: "The fifth release", milestones: [milestone], released_at: fourth_release.released_at + 1.day) }

      it "shows the associated releases and the truncation text" do
        expect(page).to have_content("Releases #{fifth_release.name} • #{fourth_release.name} • #{third_release.name} • 2 more releases")

        expect(page).to have_link(fifth_release.name, href: project_releases_path(project, anchor: fifth_release.tag))
        expect(page).to have_link(fourth_release.name, href: project_releases_path(project, anchor: fourth_release.tag))
        expect(page).to have_link(third_release.name, href: project_releases_path(project, anchor: third_release.tag))
        expect(page).to have_link("2 more releases", href: project_releases_path(project))
      end
    end
  end
end

RSpec.describe "User views milestones with no MR" do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :merge_requests_disabled) }
  let_it_be(:milestone) { create(:milestone, project: project) }

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

  it "opens milestone" do
    click_link(milestone.title)

    expect(current_path).to eq(project_milestone_path(project, milestone))
    expect(page).to have_content(milestone.title)
      .and have_selector("#tab-issues")
      .and have_no_selector("#tab-merge-requests")
  end
end
