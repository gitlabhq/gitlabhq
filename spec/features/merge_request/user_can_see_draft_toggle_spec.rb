# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees draft toggle', feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'with draft commits' do
    it 'shows the draft toggle' do
      visit project_new_merge_request_path(
        project,
        merge_request: {
          source_project_id: project.id,
          target_project_id: project.id,
          source_branch: 'wip',
          target_branch: 'master'
        })

      expect(page).to have_css('input[type="checkbox"].js-toggle-draft', count: 1)
      expect(page).to have_text('Mark as draft')
      expect(page).to have_text('Drafts cannot be merged until marked ready.')
    end
  end

  context 'without draft commits' do
    it 'shows the draft toggle' do
      visit project_new_merge_request_path(
        project,
        merge_request: {
          source_project_id: project.id,
          target_project_id: project.id,
          source_branch: 'fix',
          target_branch: 'master'
        })

      expect(page).to have_css('input[type="checkbox"].js-toggle-draft', count: 1)
      expect(page).to have_text('Mark as draft')
      expect(page).to have_text('Drafts cannot be merged until marked ready.')
    end
  end
end
