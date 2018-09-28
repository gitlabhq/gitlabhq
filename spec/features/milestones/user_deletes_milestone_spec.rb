require "rails_helper"

describe "User deletes milestone", :js do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }

  before do
    sign_in(user)
  end

  context "when milestone belongs to project" do
    let!(:milestone) { create(:milestone, parent: project, title: "project milestone") }

    it "deletes milestone" do
      project.add_developer(user)
      visit(project_milestones_path(project))
      click_link(milestone.title)
      click_button("Delete")
      click_button("Delete milestone")

      expect(page).to have_content("No milestones to show")

      visit(activity_project_path(project))

      expect(page).to have_content("#{user.name} destroyed milestone")
    end
  end

  context "when milestone belongs to group" do
    let!(:milestone_to_be_deleted) { create(:milestone, parent: group, title: "group milestone 1") }
    let!(:milestone) { create(:milestone, parent: group, title: "group milestone 2") }

    it "deletes milestone" do
      group.add_developer(user)
      visit(group_milestones_path(group))

      click_link(milestone_to_be_deleted.title)
      click_button("Delete")
      click_button("Delete milestone")

      expect(page).to have_content(milestone.title)
      expect(page).not_to have_content(milestone_to_be_deleted)
    end
  end
end
