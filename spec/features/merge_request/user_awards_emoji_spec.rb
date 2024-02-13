# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User awards emoji', :js, feature_category: :code_review_workflow do
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
      first('[data-testid="award-button"]').click
      wait_for_requests
      expect(page).to have_selector('[data-testid="award-button"].selected')
      expect(first('[data-testid="award-button"]')).to have_content '1'

      visit project_merge_request_path(project, merge_request)
      wait_for_requests

      expect(first('[data-testid="award-button"]')).to have_content '1'
    end

    it 'removes award from merge request' do
      first('[data-testid="award-button"]').click
      wait_for_requests
      expect(first('[data-testid="award-button"]')).to have_content '1'

      find('[data-testid="award-button"].selected').click
      wait_for_requests
      expect(first('[data-testid="award-button"]')).to have_content '0'

      visit project_merge_request_path(project, merge_request)
      wait_for_requests

      expect(first('[data-testid="award-button"]')).to have_content '0'
    end

    it 'adds awards to note' do
      page.within('.note-actions') do
        first('.add-reaction-button').click

        # make sure emoji popup is visible
        execute_script("window.scrollBy(0, 200)")

        find('gl-emoji[data-name="grinning"]').click
      end

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
      wait_for_requests
    end

    it 'does not see award menu button' do
      expect(page).not_to have_selector('.js-award-holder')
    end
  end
end
