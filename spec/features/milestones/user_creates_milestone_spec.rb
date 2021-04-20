# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "User creates milestone", :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  before do
    project.add_developer(user)
    sign_in(user)

    visit(new_project_milestone_path(project))
  end

  it "creates milestone" do
    title = "v2.3"

    fill_in("Title", with: title)
    fill_in("Description", with: "# Description header")
    click_button("Create milestone")

    expect(page).to have_content(title)
      .and have_content("Issues")
      .and have_header_with_correct_id_and_link(1, "Description header", "description-header")

    visit(activity_project_path(project))

    expect(page).to have_content("#{user.name} #{user.to_reference} opened milestone")
  end
end
