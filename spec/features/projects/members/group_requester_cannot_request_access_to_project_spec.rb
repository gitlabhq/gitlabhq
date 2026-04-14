# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Group requester cannot request access to project', :js,
  feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :repository, :public, namespace: group) }

  let(:group_actions_dropdown) do
    find('#group-more-action-dropdown [data-testid="groups-list-item-actions"]')
  end

  before do
    group.add_owner(owner)
    sign_in(user)
    visit group_path(group)
    perform_enqueued_jobs do
      group_actions_dropdown.click
      click_link 'Request access'
      wait_for_requests
    end
    visit project_path(project)
  end

  it 'group requester does not see the request access / withdraw access request button' do
    find_by_testid('projects-list-item-actions').click

    expect(page).not_to have_content 'Request access'
    expect(page).not_to have_content 'Withdraw access request'
  end
end
