# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User edits labels" do
  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:label) { create(:label, project: project) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_maintainer(user)
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
