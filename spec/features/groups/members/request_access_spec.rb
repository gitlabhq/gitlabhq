# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Request access', feature_category: :groups_and_projects do
  include Spec::Support::Helpers::ModalHelpers

  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:group) { create(:group, :public, owners: [owner]) }
  let!(:project) { create(:project, :private, namespace: group) }
  let(:more_actions_dropdown) do
    find('#group-more-action-dropdown [data-testid="groups-list-item-actions"]')
  end

  context 'when user has no existing access request' do
    before do
      sign_in(user)
    end

    it 'request access feature is disabled', :js do
      group.update!(request_access_enabled: false)
      visit group_path(group)
      more_actions_dropdown.click

      expect(page).not_to have_content 'Request access'
    end

    it 'user can request access to a group', :js do
      visit group_path(group)

      more_actions_dropdown.click
      request_access

      more_actions_dropdown.click

      expect(page).to have_content 'Withdraw access request'
      expect(page).not_to have_content 'Leave group'
    end

    it 'user does not see private projects', :js do
      visit group_path(group)

      more_actions_dropdown.click
      request_access

      expect(page).not_to have_content project.name
    end

    it 'user does not see group in the Dashboard > Groups page', :js do
      visit group_path(group)

      more_actions_dropdown.click
      request_access

      visit dashboard_groups_path

      expect(page).not_to have_content group.name
    end
  end

  context 'when user has request for access', :js do
    let!(:access_request) { create(:group_member, :access_request, group: group, user: user) }

    before do
      sign_in(user)
      visit group_path(group)
    end

    it 'user is not listed in the group members page' do
      within_testid 'super-sidebar' do
        click_button 'Manage'
        first(:link, 'Members').click
      end

      page.within('.content') do
        expect(page).not_to have_content(user.name)
      end
    end

    it 'user can withdraw request' do
      more_actions_dropdown.click
      withdraw_access

      expect(page).to have_content 'Your access request to the group has been withdrawn.'
    end
  end

  context 'when user is already a member' do
    let!(:access_request) { create(:group_member, :maintainer, group: group, user: user) }

    before do
      sign_in(user)
      visit group_path(group)
    end

    it 'does not see the request access button', :js do
      more_actions_dropdown.click

      expect(page).not_to have_content 'Request access'
    end
  end

  def request_access
    find_by_testid('request-access-link').click

    expect(page).to have_content 'Your request for access has been queued for review.'
  end

  def withdraw_access
    find_by_testid('withdraw-access-link').click
    accept_gl_confirm

    expect(page).to have_content 'Your access request to the group has been withdrawn.'
  end
end
