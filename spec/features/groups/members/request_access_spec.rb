# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Request access' do
  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:group) { create(:group, :public) }
  let!(:project) { create(:project, :private, namespace: group) }

  before do
    group.add_owner(owner)
    sign_in(user)
    visit group_path(group)
  end

  it 'request access feature is disabled' do
    group.update!(request_access_enabled: false)
    visit group_path(group)

    expect(page).not_to have_content 'Request Access'
  end

  it 'user can request access to a group' do
    perform_enqueued_jobs { click_link 'Request Access' }

    expect(ActionMailer::Base.deliveries.last.to).to eq [owner.notification_email]
    expect(ActionMailer::Base.deliveries.last.subject).to match "Request to join the #{group.name} group"

    expect(group.requesters.exists?(user_id: user)).to be_truthy
    expect(page).to have_content 'Your request for access has been queued for review.'

    expect(page).to have_content 'Withdraw Access Request'
    expect(page).not_to have_content 'Leave group'
  end

  it 'user does not see private projects' do
    perform_enqueued_jobs { click_link 'Request Access' }

    expect(page).not_to have_content project.name
  end

  it 'user does not see group in the Dashboard > Groups page' do
    perform_enqueued_jobs { click_link 'Request Access' }

    visit dashboard_groups_path

    expect(page).not_to have_content group.name
  end

  it 'user is not listed in the group members page' do
    click_link 'Request Access'

    expect(group.requesters.exists?(user_id: user)).to be_truthy

    first(:link, 'Members').click

    page.within('.content') do
      expect(page).not_to have_content(user.name)
    end
  end

  it 'user can withdraw its request for access' do
    click_link 'Request Access'

    expect(group.requesters.exists?(user_id: user)).to be_truthy

    click_link 'Withdraw Access Request'

    expect(group.requesters.exists?(user_id: user)).to be_falsey
    expect(page).to have_content 'Your access request to the group has been withdrawn.'
  end

  it 'member does not see the request access button' do
    group.add_owner(user)
    visit group_path(group)

    expect(page).not_to have_content 'Request Access'
  end
end
