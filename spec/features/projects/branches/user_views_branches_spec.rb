# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User views branches" do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.owner }

  before do
    sign_in(user)
  end

  context "all branches" do
    before do
      visit(project_branches_path(project))
    end

    it "shows branches" do
      expect(page).to have_content("Branches").and have_content("master")

      expect(page.all(".graph-side")).to all( have_content(/\d+/) )
    end
  end

  context "protected branches" do
    let_it_be(:protected_branch) { create(:protected_branch, project: project) }

    before do
      visit(project_protected_branches_path(project))
    end

    it "shows branches" do
      page.within(".protected-branches-list") do
        expect(page).to have_content(protected_branch.name).and have_no_content("master")
      end
    end
  end
end
