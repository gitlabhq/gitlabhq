require 'spec_helper'

feature 'Projects > Members > User requests access', feature: true do
  let(:user) { create(:user) }
  let(:master) { create(:user) }
  let(:project) { create(:project, :public) }

  background do
    project.team << [master, :master]
    login_as(user)
  end

  scenario 'user can request access to a project' do
    visit namespace_project_path(project.namespace, project)

    perform_enqueued_jobs do
      click_link 'Request Access'
    end

    expect(ActionMailer::Base.deliveries.last.to).to eq [master.notification_email]
    expect(ActionMailer::Base.deliveries.last.subject).to match /Request to join #{project.name_with_namespace} project/

    expect(project.access_requested?(user)).to be_truthy
    expect(page).to have_content 'Your request for access has been queued for review.'
    expect(page).to have_content 'Withdraw Request'
  end

  scenario 'user is not listed in the project members page' do
    visit namespace_project_path(project.namespace, project)

    click_link 'Request Access'

    expect(project.access_requested?(user)).to be_truthy

    click_link 'Members'

    visit namespace_project_project_members_path(project.namespace, project)
    page.within('.content') do
      expect(page).not_to have_content(user.name)
    end
  end

  scenario 'user can withdraw its request for access' do
    visit namespace_project_path(project.namespace, project)
    click_link 'Request Access'

    expect(project.access_requested?(user)).to be_truthy

    click_link 'Withdraw Request'

    expect(project.access_requested?(user)).to be_falsey
    expect(page).to have_content 'You withdrawn your access request to the project.'
  end
end
