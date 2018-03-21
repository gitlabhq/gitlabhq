require 'rails_helper'

describe 'Merge request > User sees WIP help message' do
  let(:project) { create(:project, :public, :repository) }
  let(:user)    { project.creator }

  before do
    project.add_master(user)
    sign_in(user)
  end

  context 'with WIP commits' do
    it 'shows a specific WIP hint' do
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
          'It looks like you have some WIP commits in this branch'
        )
      end
    end
  end

  context 'without WIP commits' do
    it 'shows the regular WIP message' do
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
          'It looks like you have some WIP commits in this branch'
        )
        expect(page).to have_text(
          "Start the title with WIP: to prevent a Work In Progress merge \
request from being merged before it's ready"
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
