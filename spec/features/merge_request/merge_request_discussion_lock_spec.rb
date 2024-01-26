# frozen_string_literal: true
# TODO use shared examples to merge this spec with discussion_lock_spec.rb
# https://gitlab.com/gitlab-org/gitlab/-/issues/255910

require 'spec_helper'

RSpec.describe 'Merge Request Discussion Lock', :js, feature_category: :code_review_workflow do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project, author: user) }

  before do
    sign_in(user)
  end

  context 'when the discussion is unlocked' do
    before do
      visit project_merge_request_path(merge_request.project, merge_request)
    end

    it 'the user can lock the merge_request' do
      find('#new-actions-header-dropdown button').click

      expect(page).to have_content('Lock discussion')
    end
  end

  context 'when the discussion is locked' do
    before do
      merge_request.update_attribute(:discussion_locked, true)
      visit project_merge_request_path(merge_request.project, merge_request)
    end

    it 'the user can unlock the merge_request' do
      find('#new-actions-header-dropdown button').click

      expect(page).to have_content('Unlock discussion')
    end
  end
end
