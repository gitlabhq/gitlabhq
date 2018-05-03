require "spec_helper"

describe "User manages members" do
  set(:group) { create(:group) }
  set(:project) { create(:project, namespace: group) }
  set(:user) { create(:user) }

  before do
    sign_in(user)
  end

  shared_examples "when group membership is unlocked" do
    before do
      group.update_attributes(membership_lock: false)

      visit(project_project_members_path(project))
    end

    it { expect(page).to have_link("Import members").and have_selector(".project-access-select") }
  end

  shared_examples "when group membership is locked" do
    before do
      group.update_attributes(membership_lock: true)

      visit(project_project_members_path(project))
    end

    it { expect(page).to have_no_button("Add members").and have_no_link("Import members") }
  end

  context "as project master" do
    before do
      project.add_master(user)
    end

    it_behaves_like "when group membership is unlocked"
    it_behaves_like "when group membership is locked"
  end

  context "as group owner" do
    before do
      group.add_owner(user)
    end

    it_behaves_like "when group membership is unlocked"
    it_behaves_like "when group membership is locked"
  end
end
