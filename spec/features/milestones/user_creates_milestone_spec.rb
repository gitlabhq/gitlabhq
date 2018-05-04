require "rails_helper"

describe "User creates milestone", :js do
  set(:user) { create(:user) }
  set(:project) { create(:project) }

  before do
    project.add_developer(user)
    sign_in(user)

    visit(new_project_milestone_path(project))
  end

  it "creates milestone" do
    TITLE = "v2.3".freeze

    fill_in("Title", with: TITLE)
    fill_in("Description", with: "# Description header")
    click_button("Create milestone")

    expect(page).to have_content(TITLE)
      .and have_content("Issues")
      .and have_header_with_correct_id_and_link(1, "Description header", "description-header")

    visit(activity_project_path(project))

    expect(page).to have_content("#{user.name} opened milestone")
  end
end
