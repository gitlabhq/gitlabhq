# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User awards emoji', :js do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, source_project: project, author: create(:user)) }
  let!(:note) { create(:note, noteable: merge_request, project: merge_request.project) }

  describe 'logged in' do
    before do
      sign_in(user)
      visit project_merge_request_path(project, merge_request)

      wait_for_requests
    end

    it 'adds award to merge request' do
      first('.js-emoji-btn').click
      expect(page).to have_selector('.js-emoji-btn.active')
      expect(first('.js-emoji-btn')).to have_content '1'

      visit project_merge_request_path(project, merge_request)
      expect(first('.js-emoji-btn')).to have_content '1'
    end

    it 'removes award from merge request' do
      first('.js-emoji-btn').click
      find('.js-emoji-btn.active').click
      expect(first('.js-emoji-btn')).to have_content '0'

      visit project_merge_request_path(project, merge_request)
      expect(first('.js-emoji-btn')).to have_content '0'
    end

    it 'has only one menu on the page' do
      first('.js-add-award').click
      expect(page).to have_selector('.emoji-menu')

      expect(page).to have_selector('.emoji-menu', count: 1)
    end

    it 'adds awards to note' do
      first('.js-note-emoji').click
      first('.emoji-menu .js-emoji-btn').click

      wait_for_requests

      expect(page).to have_selector('.js-awards-block')
    end

    describe 'the project is archived' do
      let(:project) { create(:project, :public, :repository, :archived) }

      it 'does not see award menu button' do
        expect(page).not_to have_selector('.js-award-holder')
      end
    end
  end

  describe 'logged out' do
    before do
      visit project_merge_request_path(project, merge_request)
    end

    it 'does not see award menu button' do
      expect(page).not_to have_selector('.js-award-holder')
    end
  end
end
