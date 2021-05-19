# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees draft help message' do
  let(:project) { create(:project, :public, :repository) }
  let(:user)    { project.creator }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'with draft commits' do
    it 'shows a specific draft hint' do
      visit project_new_merge_request_path(
        project,
        merge_request: {
          source_project_id: project.id,
          target_project_id: project.id,
          source_branch: 'wip',
          target_branch: 'master'
        })

      within_wip_explanation do
        expect(page).to have_text(
          'It looks like you have some draft commits in this branch'
        )
      end
    end
  end

  context 'without draft commits' do
    it 'shows the regular draft message' do
      visit project_new_merge_request_path(
        project,
        merge_request: {
          source_project_id: project.id,
          target_project_id: project.id,
          source_branch: 'fix',
          target_branch: 'master'
        })

      within_wip_explanation do
        expect(page).not_to have_text(
          'It looks like you have some draft commits in this branch'
        )
        expect(page).to have_text(
          "Start the title with Draft: to prevent a merge request that is a \
work in progress from being merged before it's ready."
        )
      end
    end
  end

  def within_wip_explanation(&block)
    page.within '.js-no-wip-explanation' do
      yield
    end
  end
end
