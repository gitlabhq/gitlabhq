# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Issues > User edits issue", :js do
  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:project_with_milestones) { create(:project_empty_repo, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:label_assigned) { create(:label, project: project, title: 'verisimilitude') }
  let_it_be(:label_unassigned) { create(:label, project: project, title: 'syzygy') }
  let_it_be(:issue) { create(:issue, project: project, author: user, assignees: [user], labels: [label_assigned]) }
  let_it_be(:issue_with_milestones) { create(:issue, project: project_with_milestones, author: user, assignees: [user]) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:milestones) { create_list(:milestone, 25, project: project_with_milestones) }

  context 'with authorized user' do
    before do
      project.add_developer(user)
      project_with_milestones.add_developer(user)
      sign_in(user)
    end

    context "from edit page" do
      before do
        stub_licensed_features(multiple_issue_assignees: false)
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
          issue.update!(title: "New title")

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
            click_on 'Edit'

            find('.dropdown-title button').click

            expect(page).not_to have_selector('.block-loading')
            expect(page).not_to have_selector('.gl-spinner')
          end
        end

        it 'can add label to issue' do
          page.within '.block.labels' do
            expect(page).to have_text('verisimilitude')
            expect(page).not_to have_text('syzygy')

            click_on 'Edit'

            wait_for_requests

            click_on 'syzygy'
            find('.dropdown-header-button').click

            wait_for_requests

            expect(page).to have_text('verisimilitude')
            expect(page).to have_text('syzygy')
          end
        end

        it 'can remove label from issue by clicking on the label `x` button' do
          page.within '.block.labels' do
            expect(page).to have_text('verisimilitude')

            within '.gl-label' do
              click_button
            end

            wait_for_requests

            expect(page).not_to have_text('verisimilitude')
          end
        end

        it 'can remove label without removing label added via quick action', :aggregate_failures do
          # Add `syzygy` label with a quick action
          fill_in 'Comment', with: '/label ~syzygy'

          click_button 'Comment'

          wait_for_requests

          page.within '.block.labels' do
            # Remove `verisimilitude` label
            within '.gl-label' do
              click_button
            end

            wait_for_requests

            expect(page).to have_text('syzygy')
            expect(page).not_to have_text('verisimilitude')
          end

          expect(page).to have_text('removed verisimilitude label')
          expect(page).not_to have_text('removed syzygy verisimilitude labels')
          expect(issue.reload.labels.map(&:title)).to contain_exactly('syzygy')
        end
      end

      describe 'update assignee' do
        context 'when GraphQL assignees widget feature flag is disabled' do
          before do
            stub_feature_flags(issue_assignees_widget: false)
          end

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

                close_dropdown_menu_if_visible

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
                expect(page).to have_content user.name

                click_link 'Edit'
                click_link user.name

                close_dropdown_menu_if_visible

                page.within '[data-testid="no-value"]' do
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

        context 'when GraphQL assignees widget feature flag is enabled' do
          context 'by authorized user' do
            it 'allows user to select unassigned' do
              visit project_issue_path(project, issue)

              page.within('.assignee') do
                expect(page).to have_content "#{user.name}"

                click_button('Edit')
                wait_for_requests

                find('[data-testid="unassign"]').click
                find('[data-testid="title"]').click
                wait_for_requests

                expect(page).to have_content 'None - assign yourself'
              end
            end

            it 'allows user to select an assignee' do
              issue2 = create(:issue, project: project, author: user)
              visit project_issue_path(project, issue2)

              page.within('.assignee') do
                expect(page).to have_content "None"
                click_button('Edit')
                wait_for_requests
              end

              page.within '.dropdown-menu-user' do
                click_link user.name
              end

              page.within('.assignee') do
                find('[data-testid="title"]').click
                wait_for_requests

                expect(page).to have_content user.name
              end
            end

            it 'allows user to unselect themselves' do
              issue2 = create(:issue, project: project, author: user, assignees: [user])

              visit project_issue_path(project, issue2)

              page.within '.assignee' do
                expect(page).to have_content user.name

                click_button('Edit')
                wait_for_requests
                click_link user.name

                find('[data-testid="title"]').click
                wait_for_requests

                expect(page).to have_content "None"
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
      end

      describe 'update milestone' do
        context 'by authorized user' do
          it 'allows user to select no milestone' do
            visit project_issue_path(project, issue)
            wait_for_requests

            page.within('.block.milestone') do
              expect(page).to have_content 'None'

              click_button 'Edit'
              wait_for_requests
              click_button 'No milestone'
              wait_for_requests

              expect(page).to have_content 'None'
            end
          end

          it 'allows user to de-select milestone' do
            visit project_issue_path(project, issue)
            wait_for_requests

            page.within('.milestone') do
              click_button 'Edit'
              wait_for_requests
              click_button milestone.title

              page.within '[data-testid="select-milestone"]' do
                expect(page).to have_content milestone.title
              end

              click_button 'Edit'
              wait_for_requests
              click_button 'No milestone'

              page.within '[data-testid="select-milestone"]' do
                expect(page).to have_content 'None'
              end
            end
          end

          it 'allows user to search milestone' do
            visit project_issue_path(project_with_milestones, issue_with_milestones)
            wait_for_requests

            page.within('.milestone') do
              click_button 'Edit'
              wait_for_requests
              # We need to enclose search string in quotes for exact match as all the milestone titles
              # within tests are prefixed with `My title`.
              find('.gl-form-input', visible: true).send_keys "\"#{milestones[0].title}\""
              wait_for_requests

              page.within '.gl-new-dropdown-contents' do
                expect(page).to have_content milestones[0].title
              end
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
            expect(page).to have_content milestone.title
          end
        end
      end

      context 'update due date' do
        before do
          # Due date widget uses GraphQL and needs to wait for requests to come back
          # The date picker won't be rendered before requests complete
          wait_for_requests
        end

        it 'adds due date to issue' do
          date = Date.today.at_beginning_of_month + 2.days

          page.within '[data-testid="due-date"]' do
            click_button 'Edit'
            page.within '.pika-single' do
              click_button date.day
            end

            wait_for_requests

            expect(find('[data-testid="sidebar-date-value"]').text).to have_content date.strftime('%b %-d, %Y')
          end
        end

        it 'removes due date from issue' do
          date = Date.today.at_beginning_of_month + 2.days

          page.within '[data-testid="due-date"]' do
            click_button 'Edit'

            page.within '.pika-single' do
              click_button date.day
            end

            wait_for_requests

            expect(page).to have_no_content 'None'

            click_button 'remove due date'
            expect(page).to have_content 'None'
          end
        end
      end
    end
  end

  context 'with unauthorized user' do
    before do
      sign_in(user)
    end

    context "from issue#show" do
      before do
        visit project_issue_path(project, issue)
      end

      describe 'updating labels' do
        it 'cannot edit labels' do
          page.within '.block.labels' do
            expect(page).not_to have_button('Edit')
          end
        end

        it 'cannot remove label with a click as it has no `x` button' do
          page.within '.block.labels' do
            within '.gl-label' do
              expect(page).not_to have_button
            end
          end
        end
      end
    end
  end
end
