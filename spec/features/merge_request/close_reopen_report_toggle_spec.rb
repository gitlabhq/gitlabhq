# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issuables Close/Reopen/Report toggle' do
  include IssuablesHelper

  let(:user) { create(:user) }

  context 'on a merge request' do
    let(:container) { find('.detail-page-header-actions') }
    let(:project) { create(:project, :repository) }
    let(:issuable) { create(:merge_request, source_project: project) }

    before do
      project.add_maintainer(user)
      login_as user
    end

    context 'when user has permission to update', :js do
      before do
        visit project_merge_request_path(project, issuable)
      end

      context 'close/reopen/report toggle' do
        it 'opens a dropdown when toggle is clicked' do
          click_button 'Toggle dropdown'

          expect(container).to have_link("Close merge request")
          expect(container).to have_link('Report abuse')
          expect(container).to have_text("Report merge requests that are abusive, inappropriate or spam.")
        end

        it 'links to Report Abuse' do
          click_button 'Toggle dropdown'
          click_link 'Report abuse'

          expect(page).to have_content('Report abuse to admin')
        end
      end

      context 'when the merge request is open' do
        let(:issuable) { create(:merge_request, :opened, source_project: project) }

        it 'shows the `Edit` and `Mark as draft` buttons' do
          expect(container).to have_link('Edit')
          expect(container).to have_link('Mark as draft')
          expect(container).not_to have_button('Report abuse')
          expect(container).not_to have_button('Close merge request')
          expect(container).not_to have_link('Reopen merge request')
        end
      end

      context 'when the merge request is closed' do
        let(:issuable) { create(:merge_request, :closed, source_project: project) }

        it 'shows both the `Edit` and `Reopen` button' do
          expect(container).to have_link('Edit')
          expect(container).not_to have_button('Report abuse')
          expect(container).not_to have_button('Close merge request')
          expect(container).to have_link('Reopen merge request')
        end

        context 'when the merge request author is the current user' do
          let(:issuable) { create(:merge_request, :closed, source_project: project, author: user) }

          it 'shows both the `Edit` and `Reopen` button' do
            expect(container).to have_link('Edit')
            expect(container).not_to have_link('Report abuse')
            expect(container).not_to have_selector('button.dropdown-toggle')
            expect(container).not_to have_button('Close merge request')
            expect(container).to have_link('Reopen merge request')
          end
        end
      end

      context 'when the merge request is merged' do
        let(:issuable) { create(:merge_request, :merged, source_project: project) }

        it 'shows only the `Edit` button' do
          expect(container).to have_link(exact_text: 'Edit')
          expect(container).not_to have_link('Report abuse')
          expect(container).not_to have_button('Close merge request')
          expect(container).not_to have_button('Reopen merge request')
        end

        context 'when the merge request author is the current user' do
          let(:issuable) { create(:merge_request, :merged, source_project: project, author: user) }

          it 'shows only the `Edit` button' do
            expect(container).to have_link(exact_text: 'Edit')
            expect(container).not_to have_link('Report abuse')
            expect(container).not_to have_button('Close merge request')
            expect(container).not_to have_button('Reopen merge request')
          end
        end
      end
    end

    context 'when user doesnt have permission to update' do
      let(:cant_project) { create(:project, :repository) }
      let(:cant_issuable) { create(:merge_request, source_project: cant_project) }

      before do
        cant_project.add_reporter(user)

        visit project_merge_request_path(cant_project, cant_issuable)
      end

      it 'only shows a `Report abuse` button' do
        expect(container).to have_link('Report abuse')
        expect(container).not_to have_button('Close merge request')
        expect(container).not_to have_button('Reopen merge request')
        expect(container).not_to have_link(exact_text: 'Edit')
      end
    end
  end
end
