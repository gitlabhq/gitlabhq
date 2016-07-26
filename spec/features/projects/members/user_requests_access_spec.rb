require 'spec_helper'

feature 'Projects > Members > User requests access', feature: true do
  let(:user) { create(:user) }
  let(:master) { create(:user) }
  let(:project) { create(:project, :public) }

  background do
    project.team << [master, :master]
    login_as(user)
    visit namespace_project_path(project.namespace, project)
  end

  scenario 'request access feature is disabled' do
    project.update_attributes(request_access_enabled: false)
    visit namespace_project_path(project.namespace, project)

    expect(page).not_to have_content 'Request Access'
  end

  scenario 'user can request access to a project' do
    perform_enqueued_jobs { click_link 'Request Access' }

    expect(ActionMailer::Base.deliveries.last.to).to eq [master.notification_email]
    expect(ActionMailer::Base.deliveries.last.subject).to eq "Request to join the #{project.name_with_namespace} project"

    expect(project.requesters.exists?(user_id: user)).to be_truthy
    expect(page).to have_content 'Your request for access has been queued for review.'

    expect(page).to have_content 'Withdraw Access Request'
    expect(page).not_to have_content 'Leave Project'
  end

  scenario 'user is not listed in the project members page' do
    click_link 'Request Access'

    expect(project.requesters.exists?(user_id: user)).to be_truthy

    open_project_settings_menu
    click_link 'Members'

    visit namespace_project_project_members_path(project.namespace, project)
    page.within('.content') do
      expect(page).not_to have_content(user.name)
    end
  end

  scenario 'user can withdraw its request for access' do
    click_link 'Request Access'

    expect(project.requesters.exists?(user_id: user)).to be_truthy

    click_link 'Withdraw Access Request'

    expect(project.requesters.exists?(user_id: user)).to be_falsey
    expect(page).to have_content 'Your access request to the project has been withdrawn.'
  end

  def open_project_settings_menu
    find('#project-settings-button').click
  end
end
