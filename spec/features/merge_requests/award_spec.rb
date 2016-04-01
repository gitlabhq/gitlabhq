require 'rails_helper'

feature 'Merge request awards', js: true, feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:merge_request) { create(:merge_request_with_diffs, source_project: project) }
  let!(:note) { create(:note_on_merge_request, project: project, noteable: merge_request, note: 'Looks good!') }

  describe 'logged in' do
    before do
      login_as(user)
      visit namespace_project_merge_request_path(project.namespace, project, merge_request)
    end

    it 'should add award to merge request' do
      first('.js-emoji-btn').click
      expect(page).to have_selector('.js-emoji-btn.active')
      expect(first('.js-emoji-btn')).to have_content '1'
    end

    it 'should remove award from merge request' do
      first('.js-emoji-btn').click
      find('.js-emoji-btn.active').click
      expect(first('.js-emoji-btn')).to have_content '0'
    end

    it 'should show award menu button in notes' do
      page.within('.note') do
        expect(page).to have_selector('.js-award-action-btn')
      end
    end

    it 'should not show award bar on note if no awards given' do
      page.within('.note') do
        expect(find('.js-awards-block', visible: false)).not_to be_visible
      end
    end

    it 'should be able to show award menu when clicking add award button in note' do
      show_note_award_menu
    end

    it 'should only have one menu on the page' do
      first('.js-add-award').click
      expect(page).to have_selector('.emoji-menu')

      page.within('.note') do
        find('.js-add-award').click
        expect(page).to have_selector('.emoji-menu', count: 1)
      end
    end

    it 'should add award to note' do
      show_note_award_menu
      award_on_note

      page.within('.note') do
        expect(find('.js-awards-block')).to be_visible
        expect(find('.js-awards-block')).to have_selector('.active')
      end
    end

    it 'should remove award from note' do
      show_note_award_menu
      award_on_note

      page.within('.note') do
        expect(find('.js-awards-block')).to be_visible
        expect(find('.js-awards-block')).to have_selector('.active')
      end

      remove_award_on_note
      sleep 0.5

      page.within('.note') do
        expect(find('.js-awards-block', visible: false)).not_to be_visible
        expect(find('.js-awards-block', visible: false)).not_to have_selector('.active')
      end
    end

    it 'should not hide award bar on notes with more than 1 award' do
      show_note_award_menu
      award_on_note

      show_note_award_menu
      award_on_note(2)

      page.within('.note') do
        expect(find('.js-awards-block')).to be_visible
        expect(find('.js-awards-block')).to have_selector('.active')
      end

      remove_award_on_note

      page.within('.note') do
        expect(find('.js-awards-block')).to be_visible
      end
    end
  end

  describe 'logged out' do
    before do
      visit namespace_project_merge_request_path(project.namespace, project, merge_request)
    end

    it 'should not see award menu button' do
      expect(page).not_to have_selector('.js-award-holder')
    end

    it 'should not see award menu button in note' do
      page.within('.note') do
        expect(page).not_to have_selector('.js-award-action-btn')
      end
    end
  end

  def show_note_award_menu
    page.within('.note') do
      find('.js-add-award').click
      expect(page).to have_selector('.emoji-menu')
    end
  end

  def award_on_note(index = 1)
    page.within('.note') do
      page.within('.emoji-menu') do
        buttons = all('.js-emoji-btn')
        buttons[index].click
      end
    end
  end

  def remove_award_on_note
    page.within('.note') do
      page.within('.js-awards-block') do
        first('.js-emoji-btn').click
      end
    end
  end
end
