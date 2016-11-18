require 'rails_helper'

feature 'Issue Sidebar', feature: true do
  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }
  let!(:user) { create(:user)}

  before do
    create(:label, project: project, title: 'bug')
    login_as(user)
  end

  context 'as a allowed user' do
    before do
      project.team << [user, :developer]
      visit_issue(project, issue)
    end

    describe 'when clicking on edit labels', js: true do
      it 'shows dropdown option to create a new label' do
        find('.block.labels .edit-link').click

        page.within('.block.labels') do
          expect(page).to have_content 'Create new'
        end
      end
    end

    context 'creating a new label', js: true do
      it 'shows option to crate a new label is present' do
        page.within('.block.labels') do
          find('.edit-link').click

          expect(page).to have_content 'Create new'
        end
      end

      it 'shows dropdown switches to "create label" section' do
        page.within('.block.labels') do
          find('.edit-link').click
          click_link 'Create new'

          expect(page).to have_content 'Create new label'
        end
      end

      it 'adds new label' do
        page.within('.block.labels') do
          find('.edit-link').click
          sleep 1
          click_link 'Create new'

          fill_in 'new_label_name', with: 'wontfix'
          page.find(".suggest-colors a", match: :first).click
          click_button 'Create'

          page.within('.dropdown-page-one') do
            expect(page).to have_content 'wontfix'
          end
        end
      end
    end
  end

  context 'as a guest' do
    before do
      project.team << [user, :guest]
      visit_issue(project, issue)
    end

    it 'does not have a option to edit labels' do
      expect(page).not_to have_selector('.block.labels .edit-link')
    end
  end

  context 'updating weight', js: true do
    before do
      project.team << [user, :master]
      visit_issue(project, issue)
    end

    it 'updates weight in sidebar to 1' do
      page.within '.weight' do
        click_link 'Edit'
        click_link '1'

        page.within '.value' do
          expect(page).to have_content '1'
        end
      end
    end

    it 'updates weight in sidebar to no weight' do
      page.within '.weight' do
        click_link 'Edit'
        click_link 'No Weight'

        page.within '.value' do
          expect(page).to have_content 'None'
        end
      end
    end
  end

  describe 'Time tracking slash commands', js: true do
    include WaitForAjax

    let(:issue) { create(:issue, author: @user, project: project) }

    before do
      project.team << [user, :developer]
      visit_issue(project, issue)
    end

    it 'renders the sidebar component empty state' do
      page.within '.issuable-sidebar' do
        expect(page).to have_content 'No estimate or time spent'
      end
    end

    it 'updates the sidebar component when estimate is added' do
      submit_time('/estimate 3w 1d 1h')

      page.within '.time-tracking-estimate-only' do
        expect(page).to have_content '3w 1d 1h'
      end
    end

    it 'updates the sidebar component when spent is added' do
      submit_time('/spend 3w 1d 1h')

      page.within '.time-tracking-spend-only' do
        expect(page).to have_content '3w 1d 1h'
      end
    end

    it 'shows the comparison when estimate and spent are added' do
      submit_time('/estimate 3w 1d 1h')
      submit_time('/spend 3w 1d 1h')

      page.within '.time-tracking-pane-compare' do
        expect(page).to have_content '3w 1d 1h'
      end
    end

    it 'updates the sidebar component when estimate is removed' do
      submit_time('/estimate 3w 1d 1h')
      submit_time('/remove_estimate')

      page.within '#issuable-time-tracker' do
        expect(page).to have_content 'No estimate or time spent'
      end
    end

    it 'updates the sidebar component when spent is removed' do
      submit_time('/spend 3w 1d 1h')
      submit_time('/remove_time_spent')

      page.within '#issuable-time-tracker' do
        expect(page).to have_content 'No estimate or time spent'
      end
    end

    it 'shows the help state when icon is clicked' do
      page.within '#issuable-time-tracker' do
        find('.help-button').click
        expect(page).to have_content 'Track time with slash commands'
        expect(page).to have_content 'Learn more'
      end
    end
  end

  def submit_time(slash_command)
    fill_in 'note[note]', with: slash_command
    click_button 'Comment'
    wait_for_ajax
  end

  def visit_issue(project, issue)
    visit namespace_project_issue_path(project.namespace, project, issue)
  end
end
