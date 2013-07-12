require 'spec_helper'

describe "SparkleInvite" do
  let!(:new_member) { create(:user) }

  before do
    Gitlab.config.sparkle_share['enable'] = true
    login_as :user
    project = create(:project)
    project.team << [@user, :master]
    visit new_project_team_member_path(project)

    find('#user_ids').set(new_member.id.to_s)
    select "Developer", from: "project_access"
  end

  it "the last email should contain a link to sparkle share" do
    UsersProject.observers.enable :users_project_observer do
      click_button "Add users"
      email = ActionMailer::Base.deliveries.last
      email.text_part.body.should have_content('sparkleshare://addProject')
    end
  end
end
