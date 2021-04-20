# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User invites from a comment", :js do
  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:user) { project.owner }

  before do
    sign_in(user)
  end

  it "launches the invite modal from invite link on a comment" do
    stub_experiments(invite_members_in_comment: :invite_member_link)

    visit project_issue_path(project, issue)

    page.within(".new-note") do
      click_button 'Invite Member'
    end

    expect(page).to have_content("You're inviting members to the")
  end
end
