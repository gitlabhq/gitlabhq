require 'spec_helper'

feature 'Projects > Members > Master manages access requests', feature: true do
  let(:user) { create(:user) }
  let(:master) { create(:user) }
  let(:project) { create(:project, :public) }

  background do
    project.request_access(user)
    project.team << [master, :master]
    login_as(master)
  end

  scenario 'master can see access requests' do
    visit namespace_project_project_members_path(project.namespace, project)

    expect_visible_access_request(project, user)
  end

  scenario 'master can grant access' do
    visit namespace_project_project_members_path(project.namespace, project)

    expect_visible_access_request(project, user)

    perform_enqueued_jobs { click_on 'Grant access' }

    expect(ActionMailer::Base.deliveries.last.to).to eq [user.notification_email]
    expect(ActionMailer::Base.deliveries.last.subject).to match "Access to the #{project.name_with_namespace} project was granted"
  end

  scenario 'master can deny access' do
    visit namespace_project_project_members_path(project.namespace, project)

    expect_visible_access_request(project, user)

    perform_enqueued_jobs { click_on 'Deny access' }

    expect(ActionMailer::Base.deliveries.last.to).to eq [user.notification_email]
    expect(ActionMailer::Base.deliveries.last.subject).to match "Access to the #{project.name_with_namespace} project was denied"
  end

  def expect_visible_access_request(project, user)
    expect(project.requesters.exists?(user_id: user)).to be_truthy
    expect(page).to have_content "#{project.name} access requests 1"
    expect(page).to have_content user.name
  end
end
