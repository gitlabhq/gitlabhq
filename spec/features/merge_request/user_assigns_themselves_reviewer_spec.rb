# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User assigns themselves as a reviewer', feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, :simple, source_project: project, author: user, description: "test mr") }

  context 'when logged in as a member of the project' do
    before do
      sign_in(user)
      visit project_merge_request_path(project, merge_request)
    end

    it 'updates updated_by', :js do
      wait_for_requests

      expect do
        page.within('.reviewer') do
          click_button 'assign yourself'
        end

        expect(find('.reviewer')).to have_content(user.name)
        wait_for_all_requests
      end.to change { merge_request.reload.updated_at }
    end

    context 'when logged in as a non-member of the project' do
      before do
        sign_in(create(:user))
        visit project_merge_request_path(project, merge_request)
      end

      it 'does not show link to assign self as Reviewer' do
        page.within('.reviewer') do
          expect(page).not_to have_content 'Assign yourself'
        end
      end
    end
  end
end
