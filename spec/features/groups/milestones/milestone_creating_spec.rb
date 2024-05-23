# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create a group milestone', :js, feature_category: :team_planning do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }

  before do
    group.add_owner(user)
    sign_in(user)

    visit new_group_milestone_path(group)
  end

  it 'renders the breadcrumbs', :aggregate_failures do
    within_testid('breadcrumb-links') do
      expect(page).to have_content("#{group.name} Milestones New milestone")

      expect(page).to have_link(group.name, href: group_path(group))
      expect(page).to have_link('Milestones', href: group_milestones_path(group))
      expect(page).to have_link('New milestone', href: new_group_milestone_path(group))
    end
  end
end
