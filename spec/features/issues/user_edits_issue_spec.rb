require "spec_helper"

describe "User edits issue", :js do
  set(:project) { create(:project_empty_repo, :public) }
  set(:user) { create(:user) }
  set(:issue) { create(:issue, project: project, author: user) }

  before do
    project.add_developer(user)
    sign_in(user)

    visit(edit_project_issue_path(project, issue))
  end

  it "previews content" do
    form = first(".gfm-form")

    page.within(form) do
      fill_in("Description", with: "Bug fixed :smile:")
      click_link("Preview")
    end

    expect(form).to have_link("Write")
  end
end
