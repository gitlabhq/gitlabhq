# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work Items List Drawer', :js, feature_category: :team_planning do
  include WorkItemsHelpers
  include ListboxHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:issue) { create(:work_item, :issue, project: project) }
  let_it_be(:label) { create(:label, project: project, title: "testing-label") }
  let_it_be(:milestone) { create(:milestone, project: project) }

  context 'when project studio is enabled' do
    before do
      enable_project_studio!(user)
    end

    context 'if user is signed in as developer' do
      let(:issuable_container) { '[data-testid="issuable-container"]' }

      before_all do
        project.add_developer(user)
      end

      context 'when accessing work item from project work item list' do
        before do
          stub_feature_flags(work_item_view_for_issues: true)

          sign_in(user)

          visit project_work_items_path(project)

          first_card.click

          wait_for_requests
        end

        it_behaves_like 'work item drawer on the list page'

        it 'updates start and due date on the list', :aggregate_failures do
          within_testid('work-item-drawer') do
            within_testid 'work-item-due-dates' do
              click_button 'Edit'
              fill_in 'Start', with: '2025-01-01'
              fill_in 'Due', with: '2025-12-31'
            end

            close_drawer
          end

          expect(first_card).to have_content('Jan 1 – Dec 31, 2025')
        end
      end

      context 'when accessing work item from project issue list' do
        before do
          stub_feature_flags(work_item_view_for_issues: true, work_item_planning_view: false)

          sign_in(user)

          visit project_issues_path(project)

          first_card.click

          wait_for_requests
        end

        it_behaves_like 'work item drawer on the list page'

        it 'updates start and due date on the list', :aggregate_failures do
          within_testid('work-item-drawer') do
            within_testid 'work-item-due-dates' do
              click_button 'Edit'
              fill_in 'Start', with: '2025-01-01'
              fill_in 'Due', with: '2025-12-31'
            end

            close_drawer
          end

          expect(first_card).to have_content('Jan 1 – Dec 31, 2025')
        end
      end
    end
  end

  context 'when project studio is disabled' do
    context 'if user is signed in as developer' do
      let(:issuable_container) { '[data-testid="issuable-container"]' }

      before_all do
        stub_feature_flags(tailwind_container_queries: false)
        project.add_developer(user)
      end

      context 'when accessing work item from project work item list' do
        before do
          stub_feature_flags(work_item_view_for_issues: true)

          sign_in(user)

          visit project_work_items_path(project)

          first_card.click

          wait_for_requests
        end

        it_behaves_like 'work item drawer on the list page'

        it 'updates start and due date on the list', :aggregate_failures do
          within_testid('work-item-drawer') do
            within_testid 'work-item-due-dates' do
              click_button 'Edit'
              fill_in 'Start', with: '2025-01-01'
              fill_in 'Due', with: '2025-12-31'
            end

            close_drawer
          end

          expect(first_card).to have_content('Jan 1 – Dec 31, 2025')
        end
      end

      context 'when accessing work item from project issue list' do
        before do
          stub_feature_flags(work_item_view_for_issues: true, work_item_planning_view: false)

          sign_in(user)

          visit project_issues_path(project)

          first_card.click

          wait_for_requests
        end

        it_behaves_like 'work item drawer on the list page'

        it 'updates start and due date on the list', :aggregate_failures do
          within_testid('work-item-drawer') do
            within_testid 'work-item-due-dates' do
              click_button 'Edit'
              fill_in 'Start', with: '2025-01-01'
              fill_in 'Due', with: '2025-12-31'
            end

            close_drawer
          end

          expect(first_card).to have_content('Jan 1 – Dec 31, 2025')
        end
      end
    end
  end

  def first_card
    find_work_item_element(issue.id)
  end
end
