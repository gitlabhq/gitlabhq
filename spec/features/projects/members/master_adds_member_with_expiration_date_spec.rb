# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Maintainer adds member with expiration date', :js, feature_category: :groups_and_projects do
  include ActiveSupport::Testing::TimeHelpers
  include Features::MembersHelpers
  include Features::InviteMembersModalHelpers

  let_it_be(:maintainer) { create(:user) }
  let_it_be(:project) { create(:project, :with_namespace_settings) }
  let_it_be(:three_days_from_now) { 3.days.from_now.to_date }
  let_it_be(:five_days_from_now) { 5.days.from_now.to_date }

  let(:new_member) { create(:user) }

  before do
    travel_to Time.now.utc.beginning_of_day

    project.add_maintainer(maintainer)
    sign_in(maintainer)
  end

  it 'expiration date is displayed in the members list' do
    visit project_project_members_path(project)

    invite_member(new_member.name, role: 'Guest', expires_at: five_days_from_now)

    page.within find_member_row(new_member) do
      expect(page).to have_field('Expiration date', with: five_days_from_now)
    end
  end

  it 'changes expiration date' do
    project.team.add_members([new_member.id], :developer, expires_at: three_days_from_now)
    visit project_project_members_path(project)

    page.within find_member_row(new_member) do
      fill_in 'Expiration date', with: five_days_from_now
      find_field('Expiration date').native.send_keys :enter

      wait_for_requests

      expect(page).to have_field('Expiration date', with: five_days_from_now)
    end
  end

  it 'clears expiration date' do
    project.team.add_members([new_member.id], :developer, expires_at: five_days_from_now)
    visit project_project_members_path(project)

    page.within find_member_row(new_member) do
      expect(page).to have_field('Expiration date', with: five_days_from_now)

      find_by_testid('clear-button').click

      wait_for_requests

      expect(page).to have_field('Expiration date', with: '')
    end
  end

  def project_member_id
    project.members.find_by(user_id: new_member).id
  end
end
