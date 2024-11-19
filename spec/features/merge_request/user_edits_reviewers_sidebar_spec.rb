# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User edits reviewers sidebar', :js, feature_category: :code_review_workflow do
  context 'with invite members considerations' do
    let_it_be(:merge_request) { create(:merge_request) }
    let_it_be(:project) { merge_request.project }
    let_it_be(:user) { create(:user) }

    before do
      sign_in(user)
    end

    context 'when a privileged user can invite in reviewer dropdown' do
      before do
        project.add_maintainer(user)
      end

      it 'shows a link for inviting members and launches invite modal' do
        visit project_merge_request_path(project, merge_request)

        page.within '.reviewer' do
          click_button 'Edit'
        end

        wait_for_requests

        page.within '.reviewers-dropdown' do
          expect(page).to have_button('Invite members')

          click_button 'Invite members'
        end

        expect(page).to have_content("You're inviting members to the")
      end
    end

    context 'when user cannot invite members in reviewer dropdown' do
      before do
        project.add_developer(user)
      end

      it 'shows author in assignee dropdown and no invite link' do
        visit project_merge_request_path(project, merge_request)

        page.within '.reviewer' do
          click_button 'Edit'
        end

        wait_for_requests

        page.within '.reviewers-dropdown' do
          expect(page).not_to have_button('Invite members')
        end
      end
    end
  end
end
