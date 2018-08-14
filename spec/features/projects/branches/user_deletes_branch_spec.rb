require "spec_helper"

describe "User deletes branch", :js do
  set(:user) { create(:user) }
  set(:project) { create(:project, :repository) }

  before do
    project.add_developer(user)
    sign_in(user)

    visit(project_branches_path(project))
  end

  it "deletes branch" do
    fill_in("branch-search", with: "improve/awesome").native.send_keys(:enter)

    page.within(".js-branch-improve\\/awesome") do
      accept_alert { find(".btn-remove").click }
    end

    expect(page).to have_css(".js-branch-improve\\/awesome", visible: :hidden)
  end
end
