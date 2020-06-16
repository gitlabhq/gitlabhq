# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Issues > User edits issue", :js do
  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue, project: project, author: user, assignees: [user]) }
  let_it_be(:label) { create(:label, project: project) }
  let_it_be(:milestone) { create(:milestone, project: project) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  context "from edit page" do
    before do
      visit edit_project_issue_path(project, issue)
    end

    it "previews content" do
      form = first(".gfm-form")

      page.within(form) do
        fill_in("Description", with: "Bug fixed :smile:")
        click_button("Preview")
      end

      expect(form).to have_button("Write")
    end

    it 'allows user to select unassigned' do
      visit edit_project_issue_path(project, issue)

      expect(page).to have_content "Assignee #{user.name}"

      first('.js-user-search').click
      click_link 'Unassigned'

      click_button 'Save changes'

      page.within('.assignee') do
        expect(page).to have_content 'None - assign yourself'
      end
    end

    context 'with due date' do
      before do
        visit edit_project_issue_path(project, issue)
      end

      it 'saves with due date' do
        date = Date.today.at_beginning_of_month.tomorrow

        fill_in 'issue_title', with: 'bug 345'
        fill_in 'issue_description', with: 'bug description'
        find('#issuable-due-date').click

        page.within '.pika-single' do
          click_button date.day
        end

        expect(find('#issuable-due-date').value).to eq date.to_s

        click_button 'Save changes'

        page.within '.issuable-sidebar' do
          expect(page).to have_content date.to_s(:medium)
        end
      end

      it 'warns about version conflict' do
        issue.update(title: "New title")

        fill_in 'issue_title', with: 'bug 345'
        fill_in 'issue_description', with: 'bug description'

        click_button 'Save changes'

        expect(page).to have_content 'Someone edited the issue the same time you did'
      end
    end
  end

  context "from issue#show" do
    before do
      visit project_issue_path(project, issue)
    end

    describe 'update labels' do
      it 'will not send ajax request when no data is changed' do
        page.within '.labels' do
          click_link 'Edit'

          find('.dropdown-menu-close', match: :first).click

          expect(page).not_to have_selector('.block-loading')
        end
      end
    end

    describe 'update assignee' do
      context 'by authorized user' do
        def close_dropdown_menu_if_visible
          find('.dropdown-menu-toggle', visible: :all).tap do |toggle|
            toggle.click if toggle.visible?
          end
        end

        it 'allows user to select unassigned' do
          visit project_issue_path(project, issue)

          page.within('.assignee') do
            expect(page).to have_content "#{user.name}"

            click_link 'Edit'
            click_link 'Unassigned'
            first('.title').click
            expect(page).to have_content 'None - assign yourself'
          end
        end

        it 'allows user to select an assignee' do
          issue2 = create(:issue, project: project, author: user)
          visit project_issue_path(project, issue2)

          page.within('.assignee') do
            expect(page).to have_content "None"
          end

          page.within '.assignee' do
            click_link 'Edit'
          end

          page.within '.dropdown-menu-user' do
            click_link user.name
          end

          page.within('.assignee') do
            expect(page).to have_content user.name
          end
        end

        it 'allows user to unselect themselves' do
          issue2 = create(:issue, project: project, author: user, assignees: [user])

          visit project_issue_path(project, issue2)

          page.within '.assignee' do
            page.within '.value .author' do
              expect(page).to have_content user.name
            end

            click_link 'Edit'
            click_link user.name

            close_dropdown_menu_if_visible

            page.within '.value .assign-yourself' do
              expect(page).to have_content "None"
            end
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
          expect(page).to have_content issue.assignees.first.name
        end
      end
    end

    describe 'update milestone' do
      context 'by authorized user' do
        it 'allows user to select unassigned' do
          visit project_issue_path(project, issue)

          page.within('.milestone') do
            expect(page).to have_content "None"
          end

          find('.block.milestone .edit-link').click
          sleep 2 # wait for ajax stuff to complete
          first('.dropdown-content li').click
          sleep 2
          page.within('.milestone') do
            expect(page).to have_content 'None'
          end
        end

        it 'allows user to de-select milestone' do
          visit project_issue_path(project, issue)

          page.within('.milestone') do
            click_link 'Edit'
            click_link milestone.title

            page.within '.value' do
              expect(page).to have_content milestone.title
            end

            click_link 'Edit'
            click_link milestone.title

            page.within '.value' do
              expect(page).to have_content 'None'
            end
          end
        end
      end

      context 'by unauthorized user' do
        let(:guest) { create(:user) }

        before do
          project.add_guest(guest)
          issue.milestone = milestone
          issue.save
        end

        it 'shows milestone text' do
          sign_out(:user)
          sign_in(guest)

          visit project_issue_path(project, issue)
          expect(page).to have_content milestone.title
        end
      end
    end

    context 'update due date' do
      it 'adds due date to issue' do
        date = Date.today.at_beginning_of_month + 2.days

        page.within '.due_date' do
          click_link 'Edit'

          page.within '.pika-single' do
            click_button date.day
          end

          wait_for_requests

          expect(find('.value').text).to have_content date.strftime('%b %-d, %Y')
        end
      end

      it 'removes due date from issue' do
        date = Date.today.at_beginning_of_month + 2.days

        page.within '.due_date' do
          click_link 'Edit'

          page.within '.pika-single' do
            click_button date.day
          end

          wait_for_requests

          expect(page).to have_no_content 'None'

          click_link 'remove due date'
          expect(page).to have_content 'None'
        end
      end
    end
  end
end
