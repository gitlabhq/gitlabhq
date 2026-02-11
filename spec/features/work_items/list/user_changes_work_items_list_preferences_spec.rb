# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work Items List User Preferences', :js, feature_category: :team_planning do
  include WorkItemsHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:issue) { create(:work_item, :issue, project: project, title: 'Test Issue', assignees: [user]) }

  context 'if user is signed in as developer' do
    before_all do
      project.add_developer(user)
      create(:callout, user: user, feature_name: :work_items_onboarding_modal)
    end

    shared_examples 'work items list preferences' do
      describe 'toggling assignee field visibility' do
        it 'hides assignee field when toggled off', :aggregate_failures do
          within(first_card) do
            expect(page).to have_testid('assignee-link')
          end
          toggle_display_option('Assignee')
          within(first_card) do
            expect(page).not_to have_testid('assignee-link')
          end
        end

        it 'shows assignee field when toggled on after toggled off', :aggregate_failures do
          2.times { toggle_display_option('Assignee') }
          within(first_card) do
            expect(page).to have_testid('assignee-link')
          end
        end
      end

      describe 'toggling side panel drawer' do
        it 'disables drawer when toggled off', :aggregate_failures do
          toggle_display_option('Open items in side panel')
          first_card.click
          wait_for_requests
          expect(page).not_to have_testid('work-item-drawer')
        end

        it 'enables drawer when toggled on', :aggregate_failures do
          2.times { toggle_display_option('Open items in side panel') }
          first_card.click
          wait_for_requests
          expect(page).to have_testid('work-item-drawer')
        end
      end
    end

    context 'when work_items_saved_views is disabled' do
      before do
        stub_feature_flags(work_items_saved_views: false)
        sign_in(user)
        visit project_work_items_path(project)
        wait_for_all_requests
      end

      it_behaves_like 'work items list preferences'
    end

    context 'when work_items_saved_views is enabled' do
      before do
        stub_feature_flags(work_items_saved_views: true)
        sign_in(user)
        visit project_work_items_path(project)
        wait_for_all_requests
      end

      it_behaves_like 'work items list preferences'
    end
  end

  def first_card
    find_work_item_element(issue.id)
  end

  def toggle_display_option(option_text)
    click_button 'Display options'
    wait_for_requests
    find('.work-item-dropdown-toggle', text: option_text).click
    wait_for_requests
    page.send_keys(:escape)
    wait_for_all_requests
  end
end
