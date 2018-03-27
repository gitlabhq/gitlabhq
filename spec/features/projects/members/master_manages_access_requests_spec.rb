require 'spec_helper'

feature 'Projects > Members > Master manages access requests' do
  let(:user) { create(:user) }
  let(:master) { create(:user) }
  let(:project) { create(:project, :public, :access_requestable) }

  background do
    project.request_access(user)
    project.add_master(master)
    sign_in(master)
  end

  scenario 'master can see access requests' do
    visit project_project_members_path(project)

    expect_visible_access_request(project, user)
  end

  scenario 'master can grant access' do
    visit project_project_members_path(project)

    expect_visible_access_request(project, user)

    perform_enqueued_jobs { click_on 'Grant access' }

    expect(ActionMailer::Base.deliveries.last.to).to eq [user.notification_email]
    expect(ActionMailer::Base.deliveries.last.subject).to match "Access to the #{project.full_name} project was granted"
  end

  scenario 'master can deny access' do
    visit project_project_members_path(project)

    expect_visible_access_request(project, user)

    perform_enqueued_jobs { click_on 'Deny access' }

    expect(ActionMailer::Base.deliveries.last.to).to eq [user.notification_email]
    expect(ActionMailer::Base.deliveries.last.subject).to match "Access to the #{project.full_name} project was denied"
  end

  def expect_visible_access_request(project, user)
    expect(project.requesters.exists?(user_id: user)).to be_truthy
    expect(page).to have_content "Users requesting access to #{project.name} 1"
    expect(page).to have_content user.name
  end
end
