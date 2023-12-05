# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Request access', feature_category: :groups_and_projects do
  include Spec::Support::Helpers::ModalHelpers

  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:group) { create(:group, :public) }
  let!(:project) { create(:project, :private, namespace: group) }
  let(:more_actions_dropdown) do
    find('[data-testid="groups-projects-more-actions-dropdown"] .gl-new-dropdown-custom-toggle')
  end

  before do
    group.add_owner(owner)
    sign_in(user)
    visit group_path(group)
  end

  it 'request access feature is disabled', :js do
    group.update!(request_access_enabled: false)
    visit group_path(group)
    more_actions_dropdown.click

    expect(page).not_to have_content 'Request Access'
  end

  it 'user can request access to a group', :js do
    perform_enqueued_jobs do
      more_actions_dropdown.click
      click_link 'Request Access'
    end

    expect(ActionMailer::Base.deliveries.last.to).to eq [owner.notification_email_or_default]
    expect(ActionMailer::Base.deliveries.last.subject).to match "Request to join the #{group.name} group"

    expect(group.requesters.exists?(user_id: user)).to be_truthy
    expect(page).to have_content 'Your request for access has been queued for review.'

    more_actions_dropdown.click

    expect(page).to have_content 'Withdraw Access Request'
    expect(page).not_to have_content 'Leave group'
  end

  it 'user does not see private projects', :js do
    perform_enqueued_jobs do
      more_actions_dropdown.click
      click_link 'Request Access'
    end

    expect(page).not_to have_content project.name
  end

  it 'user does not see group in the Dashboard > Groups page', :js do
    perform_enqueued_jobs do
      more_actions_dropdown.click
      click_link 'Request Access'
    end

    visit dashboard_groups_path

    expect(page).not_to have_content group.name
  end

  it 'user is not listed in the group members page', :js do
    more_actions_dropdown.click
    click_link 'Request Access'

    expect(group.requesters.exists?(user_id: user)).to be_truthy

    within_testid 'super-sidebar' do
      click_button 'Manage'
      first(:link, 'Members').click
    end

    page.within('.content') do
      expect(page).not_to have_content(user.name)
    end
  end

  it 'user can withdraw its request for access', :js do
    more_actions_dropdown.click
    click_link 'Request Access'

    expect(group.requesters.exists?(user_id: user)).to be_truthy

    more_actions_dropdown.click
    click_link 'Withdraw Access Request'
    accept_gl_confirm

    expect(page).to have_content 'Your access request to the group has been withdrawn.'
    expect(group.requesters.exists?(user_id: user)).to be_falsey
  end

  it 'member does not see the request access button', :js do
    group.add_owner(user)
    visit group_path(group)
    more_actions_dropdown.click

    expect(page).not_to have_content 'Request Access'
  end
end
