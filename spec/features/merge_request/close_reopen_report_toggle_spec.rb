# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issuables Close/Reopen/Report toggle', feature_category: :code_review_workflow do
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
          find('#new-actions-header-dropdown button').click

          expect(container).to have_button("Close merge request")
          expect(container).to have_button('Report abuse')
        end

        it 'links to Report Abuse' do
          find('#new-actions-header-dropdown button').click

          click_button 'Report abuse'

          expect(page).to have_content('Report abuse to administrator')
        end
      end

      context 'when the merge request is open' do
        let(:issuable) { create(:merge_request, :opened, source_project: project) }

        it 'shows the `Edit` and `Mark as draft` buttons' do
          find('#new-actions-header-dropdown button').click

          expect(container).to have_link('Edit')
          expect(container).to have_button('Mark as draft')
          expect(container).to have_button('Close merge request')
          expect(container).to have_button('Report abuse')
          expect(container).not_to have_button('Reopen merge request')
        end
      end

      context 'when the merge request is closed' do
        let(:issuable) { create(:merge_request, :closed, source_project: project) }

        it 'shows both the `Edit` and `Reopen` button' do
          find('#new-actions-header-dropdown button').click

          expect(container).to have_link('Edit')
          expect(container).to have_button('Report abuse')
          expect(container).to have_button('Reopen merge request')
          expect(container).not_to have_button('Close merge request')
        end

        context 'when the merge request author is the current user' do
          let(:issuable) { create(:merge_request, :closed, source_project: project, author: user) }

          it 'shows both the `Edit` and `Reopen` button' do
            find('#new-actions-header-dropdown button').click

            expect(container).to have_link('Edit')
            expect(container).to have_button('Reopen merge request')
            expect(container).not_to have_button('Close merge request')
            expect(container).not_to have_button('Report abuse')
          end
        end
      end

      context 'when the merge request is merged' do
        let(:issuable) { create(:merge_request, :merged, source_project: project) }

        it 'shows only the `Edit` button' do
          expect(container).to have_link(exact_text: 'Edit')
          expect(container).not_to have_button('Report abuse')
          expect(container).not_to have_button('Close merge request')
          expect(container).not_to have_button('Reopen merge request')
        end

        context 'when the merge request author is the current user' do
          let(:issuable) { create(:merge_request, :merged, source_project: project, author: user) }

          it 'shows only the `Edit` button' do
            expect(container).to have_link(exact_text: 'Edit')
            expect(container).not_to have_button('Report abuse')
            expect(container).not_to have_button('Close merge request')
            expect(container).not_to have_button('Reopen merge request')
          end
        end
      end
    end

    context 'when user doesnt have permission to update', :js do
      let(:cant_project) { create(:project, :repository) }
      let(:cant_issuable) { create(:merge_request, source_project: cant_project) }

      before do
        cant_project.add_reporter(user)

        visit project_merge_request_path(cant_project, cant_issuable)
      end

      it 'only shows a `Report abuse` button' do
        find('#new-actions-header-dropdown button').click

        expect(container).to have_button('Report abuse')
        expect(container).not_to have_button('Close merge request')
        expect(container).not_to have_button('Reopen merge request')
        expect(container).not_to have_link(exact_text: 'Edit')
      end
    end
  end
end
