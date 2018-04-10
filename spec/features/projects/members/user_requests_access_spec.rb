require 'spec_helper'

feature 'Projects > Members > User requests access', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :access_requestable, :repository) }
  let(:master) { project.owner }

  background do
    sign_in(user)
    visit project_path(project)
  end

  scenario 'request access feature is disabled' do
    project.update_attributes(request_access_enabled: false)
    visit project_path(project)

    expect(page).not_to have_content 'Request Access'
  end

  scenario 'user can request access to a project' do
    perform_enqueued_jobs { click_link 'Request Access' }

    expect(ActionMailer::Base.deliveries.last.to).to eq [master.notification_email]
    expect(ActionMailer::Base.deliveries.last.subject).to eq "Request to join the #{project.full_name} project"

    expect(project.requesters.exists?(user_id: user)).to be_truthy
    expect(page).to have_content 'Your request for access has been queued for review.'

    expect(page).to have_content 'Withdraw Access Request'
    expect(page).not_to have_content 'Leave Project'
  end

  context 'code access is restricted' do
    scenario 'user can request access' do
      project.project_feature.update!(repository_access_level: ProjectFeature::PRIVATE,
                                      builds_access_level: ProjectFeature::PRIVATE,
                                      merge_requests_access_level: ProjectFeature::PRIVATE)
      visit project_path(project)

      expect(page).to have_content 'Request Access'
    end
  end

  scenario 'user is not listed in the project members page' do
    click_link 'Request Access'

    expect(project.requesters.exists?(user_id: user)).to be_truthy

    page.within('.nav-sidebar') do
      click_link('Members')
    end

    page.within('.content') do
      expect(page).not_to have_content(user.name)
    end
  end

  scenario 'user can withdraw its request for access' do
    click_link 'Request Access'

    expect(project.requesters.exists?(user_id: user)).to be_truthy

    accept_confirm { click_link 'Withdraw Access Request' }

    expect(project.requesters.exists?(user_id: user)).to be_falsey
    expect(page).to have_content 'Your access request to the project has been withdrawn.'
  end

  def open_project_settings_menu
    page.within('.layout-nav .nav-links') do
      click_link('Settings')
    end

    page.within('.sub-nav') do
      click_link('Members')
    end
  end
end
