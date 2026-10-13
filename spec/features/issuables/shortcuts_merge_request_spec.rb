# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request shortcuts', :js, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:note_text) { 'I got this!' }

  before_all do
    project.add_developer(user)
  end

  describe 'pressing "r"' do
    before do
      create(:note, noteable: merge_request, project: project, note: note_text)
      sign_in(user)
      visit project_merge_request_path(project, merge_request)
      wait_for_requests
    end

    it 'focuses main comment field by default' do
      find('body').native.send_key('r')

      expect(page).to have_selector('.js-main-target-form .js-gfm-input:focus')
    end

    it 'quotes the selected text in main comment form' do
      select_element('#notes-list .note-comment:first-child .note-text')
      find('body').native.send_key('r')

      page.within('.js-main-target-form') do
        expect(page).to have_field('Write a comment or drag your files here…', with: "> #{note_text}\n\n")
      end
    end

    it 'quotes the selected text in the discussion reply form' do
      find('#notes-list .note:first-child .js-reply-button').click
      select_element('#notes-list .note-comment:first-child .note-text')
      find('body').native.send_key('r')

      page.within('.notes .discussion-reply-holder') do
        expect(page).to have_field('Write a comment or drag your files here…', with: "> #{note_text}\n\n")
      end
    end
  end

  describe 'pressing "a"' do
    before do
      sign_in(user)
      visit project_merge_request_path(project, merge_request)
      wait_for_requests
    end

    it "opens assignee dropdown for editing" do
      find('body').native.send_key('a')

      expect(find('.block.assignee')).to have_selector('[data-testid="listbox-search-input"]')
    end
  end

  describe 'pressing "m"' do
    before do
      sign_in(user)
      visit project_merge_request_path(project, merge_request)
      wait_for_requests
    end

    it "opens milestones dropdown for editing" do
      find('body').native.send_key('m')

      expect(find('.block.milestone')).to have_selector('[data-testid="listbox-search-input"]')
    end
  end

  describe 'pressing "l"' do
    before do
      sign_in(user)
      visit project_merge_request_path(project, merge_request)
      wait_for_requests
    end

    it "opens labels dropdown for editing" do
      find('body').native.send_key('l')

      expect(find('.js-labels-block')).to have_selector('[data-testid="listbox-search-input"]')
    end
  end
end
