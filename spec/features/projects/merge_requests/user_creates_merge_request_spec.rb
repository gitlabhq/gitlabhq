require "spec_helper"

describe "User creates a merge request", :js do
  include ProjectForksHelper

  let(:approver) { create(:user) }
  let(:project) do
    create(:project,
      :repository,
      approvals_before_merge: 1,
      merge_requests_template: template_text)
  end
  let(:template_text) { "This merge request should contain the following." }
  let(:title) { "Some feature" }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }

  before do
    project.add_maintainer(user)
    project.add_maintainer(approver)
    sign_in(user)

    project.approvers.create(user_id: approver.id)

    visit(project_new_merge_request_path(project))
  end

  it "creates a merge request" do
    allow_any_instance_of(Gitlab::AuthorityAnalyzer).to receive(:calculate).and_return([user2])

    find(".js-source-branch").click
    click_link("fix")

    find(".js-target-branch").click
    click_link("feature")

    click_button("Compare branches")

    expect(find_field("merge_request_description").value).to eq(template_text)

    # Approvers
    page.within("ul .unsaved-approvers") do
      expect(page).to have_content(approver.name)
    end

    page.within(".suggested-approvers") do
      expect(page).to have_content(user2.name)
    end

    click_link(user2.name)

    page.within("ul.approver-list") do
      expect(page).to have_content(user2.name)
    end
    # End of approvers

    fill_in("Title", with: title)
    click_button("Submit merge request")

    page.within(".merge-request") do
      expect(page).to have_content(title)
    end

    page.within(".js-issuable-actions") do
      click_link("Edit", match: :first)
    end

    page.within("ul.approver-list") do
      expect(page).to have_content(user2.name)
    end
  end

  context "to a forked project" do
    let(:forked_project) { fork_project(project, user, namespace: user.namespace, repository: true) }

    it "creates a merge request" do
      visit(project_new_merge_request_path(forked_project))

      expect(page).to have_content("Source branch").and have_content("Target branch")
      expect(find("#merge_request_target_project_id", visible: false).value).to eq(project.id.to_s)

      click_button("Compare branches and continue")

      expect(page).to have_content("You must select source and target branch")

      first(".js-source-project").click
      first(".dropdown-source-project a", text: forked_project.full_path)

      first(".js-target-project").click
      first(".dropdown-target-project a", text: project.full_path)

      first(".js-source-branch").click

      wait_for_requests

      source_branch = "fix"

      first(".js-source-branch-dropdown .dropdown-content a", text: source_branch).click

      click_button("Compare branches and continue")

      expect(page).to have_css("h3.page-title", text: "New Merge Request")

      page.within("form#new_merge_request") do
        fill_in("Title", with: title)
      end

      click_button("Assignee")

      expect(find(".js-assignee-search")["data-project-id"]).to eq(project.id.to_s)

      page.within(".dropdown-menu-user") do
        expect(page).to have_content("Unassigned")
                   .and have_content(user.name)
                   .and have_content(project.users.first.name)
      end

      click_button("Submit merge request")

      expect(page).to have_content(title).and have_content("Request to merge #{user.namespace.name}:#{source_branch} into master")
    end
  end
end
