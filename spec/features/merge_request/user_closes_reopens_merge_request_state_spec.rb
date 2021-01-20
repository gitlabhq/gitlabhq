# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User closes/reopens a merge request', :js, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/297500' do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  describe 'when open' do
    context 'when clicking the top `Close merge request` link', :aggregate_failures do
      let(:open_merge_request) { create(:merge_request, source_project: project, target_project: project) }

      before do
        visit merge_request_path(open_merge_request)
      end

      it 'can close a merge request' do
        expect(find('.status-box')).to have_content 'Open'

        within '.detail-page-header' do
          click_button 'Toggle dropdown'
          click_link 'Close merge request'
        end

        wait_for_requests

        expect(find('.status-box')).to have_content 'Closed'
      end
    end

    context 'when clicking the bottom `Close merge request` button', :aggregate_failures do
      let(:open_merge_request) { create(:merge_request, source_project: project, target_project: project) }

      before do
        visit merge_request_path(open_merge_request)
      end

      it 'can close a merge request' do
        expect(find('.status-box')).to have_content 'Open'

        within '.timeline-content-form' do
          click_button 'Close merge request'

          # Clicking the bottom `Close merge request` button does not yet update
          # the header status so for now we'll check that the button text changes
          expect(page).not_to have_button 'Close merge request'
          expect(page).to have_button 'Reopen merge request'
        end
      end
    end
  end

  describe 'when closed' do
    context 'when clicking the top `Reopen merge request` link', :aggregate_failures do
      let(:closed_merge_request) { create(:merge_request, source_project: project, target_project: project, state: 'closed') }

      before do
        visit merge_request_path(closed_merge_request)
      end

      it 'can reopen a merge request' do
        expect(find('.status-box')).to have_content 'Closed'

        within '.detail-page-header' do
          click_button 'Toggle dropdown'
          click_link 'Reopen merge request'
        end

        wait_for_requests

        expect(find('.status-box')).to have_content 'Open'
      end
    end

    context 'when clicking the bottom `Reopen merge request` button', :aggregate_failures do
      let(:closed_merge_request) { create(:merge_request, source_project: project, target_project: project, state: 'closed') }

      before do
        visit merge_request_path(closed_merge_request)
      end

      it 'can reopen a merge request' do
        expect(find('.status-box')).to have_content 'Closed'

        within '.timeline-content-form' do
          click_button 'Reopen merge request'

          # Clicking the bottom `Reopen merge request` button does not yet update
          # the header status so for now we'll check that the button text changes
          expect(page).not_to have_button 'Reopen merge request'
          expect(page).to have_button 'Close merge request'
        end
      end
    end
  end
end
