# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User deletes branch", :js do
  let_it_be(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    project.add_developer(user)
    sign_in(user)

    visit(project_branches_path(project))
  end

  it "deletes branch" do
    fill_in("branch-search", with: "improve/awesome").native.send_keys(:enter)

    page.within(".js-branch-improve\\/awesome") do
      accept_alert { find(".btn-danger").click }
    end

    wait_for_requests

    expect(page).to have_css(".js-branch-improve\\/awesome", visible: :hidden)
  end
end
