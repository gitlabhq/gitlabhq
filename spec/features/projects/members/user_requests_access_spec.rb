# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > User requests access', :js, feature_category: :groups_and_projects do
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }

  let(:owner) { project.first_owner }
  let(:more_actions_dropdown) do
    find('[data-testid="groups-projects-more-actions-dropdown"] .gl-new-dropdown-custom-toggle')
  end

  before do
    sign_in(user)
    project.add_maintainer(maintainer)
    visit project_path(project)
  end

  it 'request access feature is disabled', :js do
    project.update!(request_access_enabled: false)
    visit project_path(project)

    more_actions_dropdown.click
    expect(page).not_to have_content 'Request Access'
  end

  it 'user can request access to a project', :js do
    perform_enqueued_jobs do
      more_actions_dropdown.click
      click_link 'Request Access'
    end

    expect(ActionMailer::Base.deliveries.map(&:to)).to match_array([[owner.notification_email_or_default], [maintainer.notification_email_or_default]])
    expect(ActionMailer::Base.deliveries.last.subject).to eq "Request to join the #{project.full_name} project"

    expect(project.requesters.exists?(user_id: user)).to be_truthy

    more_actions_dropdown.click
    expect(page).to have_content 'Withdraw Access Request'
    expect(page).not_to have_content 'Leave Project'
  end

  context 'code access is restricted' do
    it 'user can request access', :js do
      project.project_feature.update!(
        repository_access_level: ProjectFeature::PRIVATE,
        builds_access_level: ProjectFeature::PRIVATE,
        merge_requests_access_level: ProjectFeature::PRIVATE
      )
      visit project_path(project)
      more_actions_dropdown.click

      expect(page).to have_content 'Request Access'
    end
  end

  it 'user is not listed in the project members page', :js do
    more_actions_dropdown.click
    click_link 'Request Access'

    expect(project.requesters.exists?(user_id: user)).to be_truthy

    within_testid('super-sidebar') do
      click_button 'Manage'
      click_link 'Members'
    end

    page.within('.content') do
      expect(page).not_to have_content(user.name)
    end
  end

  it 'user can withdraw its request for access', :js do
    more_actions_dropdown.click
    click_link 'Request Access'

    expect(project.requesters.exists?(user_id: user)).to be_truthy

    more_actions_dropdown.click
    accept_gl_confirm { click_link 'Withdraw Access Request' }

    more_actions_dropdown.click
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
