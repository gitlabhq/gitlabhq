require "spec_helper"

describe "User edits labels" do
  set(:project) { create(:project_empty_repo, :public) }
  set(:label) { create(:label, project: project) }
  set(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(edit_project_label_path(project, label))
  end

  it "updates label's title" do
    new_title = "fix"

    fill_in("Title", with: new_title)
    click_button("Save changes")

    page.within(".other-labels .manage-labels-list") do
      expect(page).to have_content(new_title).and have_no_content(label.title)
    end
  end
end
