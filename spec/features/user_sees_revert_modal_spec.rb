# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees revert modal', :js, :sidekiq_might_not_need_inline,
  feature_category: :code_review_workflow do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, source_project: project) }

  shared_examples 'showing the revert modal' do
    it 'shows the revert modal' do
      click_button('Revert')

      wait_for_requests

      within_testid('modal-commit') do
        expect(page).to have_content 'Revert this merge request'
      end
    end
  end

  before do
    sign_in(user)
    visit(project_merge_request_path(project, merge_request))

    page.within('.mr-state-widget') do
      click_button 'Merge'
    end

    wait_for_all_requests

    page.refresh

    wait_for_requests
  end

  context 'without page reload after merge validates js correctly loaded' do
    it_behaves_like 'showing the revert modal'
  end

  context 'with page reload validates js correctly loaded' do
    before do
      visit(merge_request_path(merge_request))
    end

    it_behaves_like 'showing the revert modal'
  end
end
