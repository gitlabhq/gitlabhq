# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > User requests access', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }

  let(:maintainer) { project.owner }

  before do
    sign_in(user)
    visit project_path(project)
  end

  it 'request access feature is disabled' do
    project.update!(request_access_enabled: false)
    visit project_path(project)

    expect(page).not_to have_content 'Request Access'
  end

  it 'user can request access to a project' do
    perform_enqueued_jobs { click_link 'Request Access' }

    expect(ActionMailer::Base.deliveries.last.to).to eq [maintainer.notification_email]
    expect(ActionMailer::Base.deliveries.last.subject).to eq "Request to join the #{project.full_name} project"

    expect(project.requesters.exists?(user_id: user)).to be_truthy

    expect(page).to have_content 'Withdraw Access Request'
    expect(page).not_to have_content 'Leave Project'
  end

  context 'code access is restricted' do
    it 'user can request access' do
      project.project_feature.update!(repository_access_level: ProjectFeature::PRIVATE,
                                      builds_access_level: ProjectFeature::PRIVATE,
                                      merge_requests_access_level: ProjectFeature::PRIVATE)
      visit project_path(project)

      expect(page).to have_content 'Request Access'
    end
  end

  it 'user is not listed in the project members page' do
    click_link 'Request Access'

    expect(project.requesters.exists?(user_id: user)).to be_truthy

    click_link 'Project information'

    page.within('.nav-sidebar') do
      click_link('Members')
    end

    page.within('.content') do
      expect(page).not_to have_content(user.name)
    end
  end

  it 'user can withdraw its request for access' do
    click_link 'Request Access'

    expect(project.requesters.exists?(user_id: user)).to be_truthy

    accept_confirm { click_link 'Withdraw Access Request' }

    expect(page).not_to have_content 'Withdraw Access Request'
    expect(page).to have_content 'Request Access'
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
