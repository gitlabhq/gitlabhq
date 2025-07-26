# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Issues > User edits issue", :js, feature_category: :team_planning do
  include ListboxHelpers

  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:project_with_milestones) { create(:project_empty_repo, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:label_assigned) { create(:label, project: project, title: 'verisimilitude') }
  let_it_be(:label_unassigned) { create(:label, project: project, title: 'syzygy') }
  let_it_be(:issue) { create(:issue, project: project, author: user, assignees: [user], labels: [label_assigned]) }
  let_it_be(:issue_with_milestones) { create(:issue, project: project_with_milestones, author: user, assignees: [user]) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:milestones) { create_list(:milestone, 25, project: project_with_milestones) }

  before do
    stub_feature_flags(work_item_view_for_issues: true)
  end

  context 'with authorized user' do
    before do
      project.add_developer(user)
      project_with_milestones.add_developer(user)
      sign_in(user)
    end

    describe 'edit description' do
      it 'places focus on the web editor' do
        visit project_issue_path(project, issue)

        click_button 'Edit title and description'

        expect(page).to have_field('Title')
        expect(page).to have_field('Description')

        click_button('Switch to rich text editing', match: :first)

        expect(page).to have_css('[data-testid="content_editor_editablebox"]')

        refresh

        click_button 'Edit title and description'

        expect(page).to have_css('[data-testid="content_editor_editablebox"]')

        click_button('Switch to plain text editing', match: :first)

        expect(page).to have_field('Description')
      end
    end

    describe 'update labels' do
      before do
        visit project_issue_path(project, issue)
      end

      it 'can add label to issue' do
        within_testid('work-item-labels') do
          expect(page).to have_link('verisimilitude')
          expect(page).not_to have_link('syzygy')

          click_button 'Edit'
          select_listbox_item('syzygy')
          send_keys(:escape)

          expect(page).to have_link('verisimilitude')
          expect(page).to have_link('syzygy')
        end
      end

      it 'can remove label from issue by clicking on the label `x` button' do
        within_testid('work-item-labels') do
          expect(page).to have_link('verisimilitude')

          click_button 'Remove label'

          expect(page).not_to have_link('verisimilitude')
        end
      end

      it 'can remove label without removing label added via quick action', :aggregate_failures do
        fill_in 'Add a reply', with: '/label ~syzygy'
        click_button 'Comment'

        expect(page).to have_text('added syzygy label just now')

        within_testid('work-item-labels') do
          within '.gl-label', text: 'verisimilitude' do
            click_button 'Remove label'
          end

          expect(page).not_to have_link('verisimilitude')
          expect(page).to have_link('syzygy')
        end

        expect(page).to have_text('removed verisimilitude label')
        expect(page).not_to have_text('removed syzygy verisimilitude labels')
      end
    end

    describe 'update assignee' do
      context 'by authorized user' do
        it 'allows user to clear assignment' do
          visit project_issue_path(project, issue)

          within_testid('work-item-assignees') do
            expect(page).to have_link user.name

            click_button('Edit')
            click_button('Clear')

            expect(page).to have_text 'None'
          end
        end

        it 'allows user to select an assignee' do
          issue2 = create(:issue, project: project, author: user)
          visit project_issue_path(project, issue2)

          within_testid('work-item-assignees') do
            expect(page).to have_text "None"
            click_button('Edit')
            select_listbox_item(user.name)

            expect(page).to have_link user.name
          end
        end
      end

      context 'by unauthorized user' do
        let(:guest) { create(:user) }

        before do
          project.add_guest(guest)
        end

        it 'shows assignee text' do
          sign_out(:user)
          sign_in(guest)
          visit project_issue_path(project, issue)

          within_testid('work-item-assignees') do
            expect(page).to have_link issue.assignees.first.name
          end
        end
      end
    end

    describe 'update milestone' do
      context 'by authorized user' do
        it 'allows user to de-select milestone' do
          visit project_issue_path(project, issue)

          within_testid 'work-item-milestone' do
            click_button 'Edit'
            select_listbox_item(milestone.title)

            expect(page).to have_link milestone.title

            click_button 'Edit'
            click_button 'Clear'

            expect(page).to have_text 'None'
          end
        end

        it 'allows user to search milestone' do
          visit project_issue_path(project_with_milestones, issue_with_milestones)

          within_testid 'work-item-milestone' do
            click_button 'Edit'
            send_keys "\"#{milestones[0].title}\""

            expect_listbox_item(milestones[0].title)
          end
        end
      end

      context 'by unauthorized user' do
        let(:guest) { create(:user) }

        before do
          project.add_guest(guest)
          issue.milestone = milestone
          issue.save!
        end

        it 'shows milestone text' do
          sign_out(:user)
          sign_in(guest)
          visit project_issue_path(project, issue)

          within_testid 'work-item-milestone' do
            expect(page).to have_link milestone.title
          end
        end
      end
    end

    context 'update date' do
      before do
        visit project_issue_path(project, issue)
      end

      it 'adds and removes due date from issue' do
        date = Date.today.at_beginning_of_month + 2.days

        within_testid('work-item-due-dates') do
          click_button 'Edit'
          fill_in 'Due', with: date.iso8601
          send_keys :enter
          click_button 'Apply'

          expect(page).to have_text date.strftime('%b %-d, %Y')

          click_button 'Edit'
          click_button 'Clear date'
          click_button 'Apply'

          expect(page).not_to have_text date.strftime('%b %-d, %Y')
        end
      end
    end
  end

  context 'with unauthorized user' do
    before do
      sign_in(user)
      visit project_issue_path(project, issue)
    end

    describe 'updating labels' do
      it 'cannot edit labels or remove label with a click as it has no `x` button' do
        within_testid('work-item-labels') do
          expect(page).not_to have_button 'Edit'
          expect(page).not_to have_button 'Remove label'
        end
      end
    end
  end
end
