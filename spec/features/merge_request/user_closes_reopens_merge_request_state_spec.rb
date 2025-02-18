# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User closes/reopens a merge request', :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  describe 'when open' do
    let(:open_merge_request) { create(:merge_request, source_project: project, target_project: project) }

    before do
      visit merge_request_path(open_merge_request)
    end

    context 'when clicking the top `Close merge request` button' do
      it 'closes the merge request' do
        expect(page).to have_css('.gl-badge', text: 'Open')

        within '.detail-page-header' do
          click_button 'Merge request actions'
          click_button 'Close merge request'
        end

        expect(page).to have_css('.gl-badge', text: 'Closed')
      end
    end

    context 'when clicking the bottom `Close merge request` button' do
      it 'closes the merge request' do
        expect(page).to have_css('.gl-badge', text: 'Open')

        within '.timeline-content-form' do
          click_button 'Close merge request'
        end

        expect(page).to have_css('.gl-badge', text: 'Closed')
      end
    end
  end

  describe 'when closed' do
    let(:closed_merge_request) { create(:merge_request, source_project: project, target_project: project, state: 'closed') }

    before do
      visit merge_request_path(closed_merge_request)
    end

    context 'when clicking the top `Reopen merge request` button' do
      it 'reopens the merge request', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/444681' do
        expect(page).to have_css('.gl-badge', text: 'Closed')

        within '.detail-page-header' do
          click_button 'Merge request actions'
          click_button 'Reopen merge request'
        end

        expect(page).to have_css('.gl-badge', text: 'Open')
      end
    end

    context 'when clicking the bottom `Reopen merge request` button' do
      it 'reopens the merge request' do
        expect(page).to have_css('.gl-badge', text: 'Closed')

        within '.timeline-content-form' do
          click_button 'Reopen merge request'
        end

        expect(page).to have_css('.gl-badge', text: 'Open')
      end
    end
  end
end
