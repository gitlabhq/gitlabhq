# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees system notes', :js, feature_category: :code_review_workflow do
  let(:public_project) { create(:project, :public, :repository) }
  let(:private_project) { create(:project, :private, :repository) }
  let(:user)            { private_project.creator }
  let(:issue) { create(:issue, project: private_project) }
  let(:merge_request) { create(:merge_request, source_project: public_project, source_branch: 'markdown') }
  let!(:note) { create(:note_on_merge_request, :system, noteable: merge_request, project: public_project, note: "mentioned in #{issue.to_reference(public_project)}") }

  context 'when logged-in as a member of the private project' do
    before do
      private_project.add_developer(user)
      sign_in(user)
    end

    it 'shows the system note' do
      visit project_merge_request_path(public_project, merge_request)

      expect(page).to have_css('.system-note')
    end
  end

  context 'when not logged-in' do
    it 'hides the system note' do
      visit project_merge_request_path(public_project, merge_request)

      expect(page).not_to have_css('.system-note')
    end
  end
end
