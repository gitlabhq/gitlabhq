require "spec_helper"

describe "User creates branch", :js do
  include Spec::Support::Helpers::Features::BranchesHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    project.add_developer(user)
    sign_in(user)

    visit(new_project_branch_path(project))
  end

  it "creates new branch" do
    BRANCH_NAME = "deploy_keys".freeze

    create_branch(BRANCH_NAME)

    expect(page).to have_content(BRANCH_NAME)
  end

  context "when branch name is invalid" do
    it "does not create new branch" do
      INVALID_BRANCH_NAME = "1.0 stable".freeze

      fill_in("branch_name", with: INVALID_BRANCH_NAME)
      page.find("body").click # defocus the branch_name input

      select_branch("master")
      click_button("Create branch")

      expect(page).to have_content("Branch name is invalid")
      expect(page).to have_content("can't contain spaces")
    end
  end

  context "when branch name already exists" do
    it "does not create new branch" do
      create_branch("master")

      expect(page).to have_content("Branch already exists")
    end
  end
end
