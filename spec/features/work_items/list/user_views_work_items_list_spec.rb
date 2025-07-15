# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work Items List', :js, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:project_internal) { create(:project_empty_repo, :internal, group: group) }

  context 'if user is signed in as owner' do
    let(:issuable_container) { '[data-testid="issuable-container"]' }

    before_all do
      group.add_owner(user)
    end

    before do
      sign_in(user)

      visit project_work_items_path(project)

      wait_for_all_requests
    end

    it_behaves_like 'no work items in the list'

    context 'when the work items list page renders' do
      let_it_be(:issue) { create(:work_item, :issue, project: project, title: 'There is an issue in the list') }
      let_it_be(:task) { create(:work_item, :task, project: project, title: 'The task belongs to the issue') }
      let_it_be(:incident) do
        create(:work_item, :incident, project: project, title: 'An incident happened while loading the list')
      end

      let_it_be(:closed_issue) { create(:work_item, :closed, project: project) }

      it 'show actions based on user permissions' do
        expect(page).to have_link('New item')
        expect(page).to have_button('Bulk edit')
      end

      it 'show default sort order' do
        within_testid('issuable-search-container') do
          expect(page).to have_button('Created date')
          expect(page).to have_button('Sort direction: Descending')
        end
      end

      it_behaves_like 'shows open items in the list' do
        let(:open_item) { task }
        let(:closed_item) { closed_issue }
      end

      context 'when viewing closed work items' do
        before do
          visit project_work_items_path(project, state: :closed)
          wait_for_all_requests
        end

        it_behaves_like 'shows closed items in the list' do
          let(:open_item) { issue }
          let(:closed_item) { closed_issue }
        end
      end

      context 'with all the metadata' do
        let_it_be(:label) { create(:label, title: 'Label 1', project: project) }
        let_it_be(:milestone) { create(:milestone, project: project, title: 'v1') }
        let_it_be(:task) do
          create(
            :work_item,
            :task,
            project: project,
            labels: [label],
            assignees: [user],
            milestone: milestone,
            due_date: '2025-12-31',
            time_estimate: 12.hours
          )
        end

        let_it_be(:award_emoji_upvote) { create(:award_emoji, :upvote, user: user, awardable: task) }
        let_it_be(:award_emoji_downvote) { create(:award_emoji, :downvote, user: user, awardable: task) }

        it_behaves_like 'dates on the work items list' do
          let(:date) { 'Dec 31, 2025' }
        end

        it 'display available metadata' do
          within(all(issuable_container)[0]) do
            expect(page).to have_link(milestone.title)
              .and have_link(label.name)

            expect(page).to have_link(user.name, href: user_path(user))
            expect(find_by_testid('time-estimate-title').text).to have_text('4h')
            expect(page).to have_text(%r{created .* by #{task.author.name}})
            expect(page).to have_selector('.issuable-meta [data-testid="issuable-upvotes"]')
          end
        end
      end
    end

    context 'with pagination' do
      let_it_be(:work_items) do
        create_list(:work_item, 10, :issue, project: project)
        create_list(:work_item, 10, :task, project: project)
        create_list(:work_item, 5, :incident, project: project)
      end

      before do
        visit project_work_items_path(project)
      end

      it_behaves_like 'pagination on the work items list page'

      it 'respects per_page parameter in URL' do
        visit project_work_items_path(project, first_page_size: 50)

        expect(page).to have_selector(issuable_container, count: 25)
      end
    end
  end

  context 'when user is not signed in' do
    let_it_be(:confidential_issue) do
      create(:work_item, :issue, :confidential, project: project, title: 'Confidential issue')
    end

    before do
      visit project_work_items_path(project)

      wait_for_all_requests
    end

    it 'shows actions based on user permissions' do
      expect(page).not_to have_button('New item')
      expect(page).not_to have_button('Bulk edit')
    end

    it 'does not show confidential items' do
      expect(page).not_to have_content(confidential_issue.title)
    end
  end

  context 'with internal project visibility level' do
    let_it_be(:open_work_item) { create(:work_item, :issue, project: project_internal, title: 'Open work item') }

    let_it_be(:closed_work_item) do
      create(:work_item, :issue, :closed, project: project_internal, title: 'Closed work item')
    end

    context 'when a member views all work items' do
      before_all do
        project_internal.add_developer(user)
      end

      before do
        sign_in(user)
        visit project_work_items_path(project_internal, state: :all)
        wait_for_all_requests
      end

      it_behaves_like 'shows all items in the list' do
        let(:open_item) { open_work_item }
        let(:closed_item) { closed_work_item }
      end
    end
  end
end
