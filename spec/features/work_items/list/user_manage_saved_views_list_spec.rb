# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User manage saved views list', :js, feature_category: :team_planning do
  include FilteredSearchHelpers
  include WorkItemsHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:guest_user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:label) { create(:label, title: 'bug', project: project) }
  let_it_be(:issue) do
    create(:work_item, :issue, project: project, title: 'Test issue', labels: [label])
  end

  before_all do
    project.add_planner(user)
    project.add_guest(guest_user)
    create(:callout, user: user, feature_name: :work_items_onboarding_modal)
    create(:callout, user: guest_user, feature_name: :work_items_onboarding_modal)
  end

  context 'when user has planner role' do
    before do
      sign_in(user)
    end

    context 'when creating a view from the add view dropdown' do
      before do
        visit project_work_items_path(project)
        wait_for_all_requests
      end

      include_examples 'saved view creation from add view dropdown'
    end

    context 'when creating a view via the save view button with filters applied' do
      before do
        visit project_work_items_path(project)
        wait_for_all_requests
      end

      include_examples 'saved view creation via save view button with filters'
    end
  end

  context 'when user has guest role' do
    before do
      sign_in(guest_user)
      visit project_work_items_path(project)
      wait_for_all_requests
    end

    include_examples 'guest user saved view restrictions'
  end
end
