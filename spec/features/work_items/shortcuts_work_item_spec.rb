# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work item keyboard shortcuts', :js, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:work_item) { create(:work_item, project: project) }
  let_it_be(:work_items_path) { project_work_item_path(project, work_item.iid) }
  let_it_be(:note_text) { 'I got this!' }

  context 'for signed in user' do
    before_all do
      project.add_developer(user)
    end

    before do
      create(:note, noteable: work_item, project: project, note: note_text)
      sign_in(user)
      visit work_items_path

      wait_for_requests
    end

    describe 'sidebar' do
      it 'pressing m opens milestones dropdown for editing' do
        find('body').native.send_key('m')

        expect(find_by_testid('work-item-milestone')).to have_selector('.gl-new-dropdown-panel')
      end

      it 'pressing l opens labels dropdown for editing' do
        find('body').native.send_key('l')

        expect(find_by_testid('work-item-labels')).to have_selector('.gl-new-dropdown-panel')
      end

      it 'pressing a opens assignee dropdown for editing' do
        find('body').native.send_key('a')

        expect(find_by_testid('work-item-assignees')).to have_selector('.gl-new-dropdown-panel')
      end

      it 'pressing e starts editing mode' do
        find('body').native.send_key('e')

        expect(page).to have_selector('[data-testid="work-item-title-input"]')
        expect(page).to have_selector('form textarea#work-item-description')
      end
    end

    describe 'pressing r' do
      it 'focuses main comment field by default' do
        find('body').native.send_key('r')

        expect(page).to have_selector('.js-main-target-form .js-gfm-input:focus')
      end

      it 'quotes the selected text in main comment form' do
        select_element('.notes .note-comment:first-child .note-text')
        find('body').native.send_key('r')

        page.within('.js-main-target-form') do
          expect(page).to have_field('Write a comment or drag your files here…', with: "> #{note_text}\n\n")
        end
      end

      it 'quotes the selected text in the discussion reply form' do
        click_button 'Reply to comment'

        select_element('.notes .note-comment:first-child .note-text')

        find('body').native.send_key('r')
        page.within('.notes .discussion-reply-holder') do
          expect(page).to have_field('Write a comment or drag your files here…', with: "> #{note_text}\n\n")
        end
      end
    end

    describe 'navigation' do
      it 'pressing . opens web IDE' do
        new_tab = window_opened_by { find('body').native.send_key('.') }

        within_window new_tab do
          expect(page).to have_selector('.ide-view')
        end
      end
    end
  end
end
