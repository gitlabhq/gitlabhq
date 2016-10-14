require 'spec_helper'

feature 'Merge request created from fork' do
  given(:user) { create(:user) }
  given(:project) { create(:project, :public) }
  given(:fork_project) { create(:project, :public) }

  given!(:merge_request) do
    create(:forked_project_link, forked_to_project: fork_project,
                                 forked_from_project: project)

    create(:merge_request_with_diffs, source_project: fork_project,
                                      target_project: project,
                                      description: 'Test merge request')
  end

  background do
    fork_project.team << [user, :master]
    login_as user
  end

  scenario 'user can access merge request' do
    visit_merge_request(merge_request)

    expect(page).to have_content 'Test merge request'
  end

  context 'pipeline present in source project' do
    include WaitForAjax

    given(:pipeline) do
      create(:ci_pipeline,
             project: fork_project,
             sha: merge_request.diff_head_sha,
             ref: merge_request.source_branch)
    end

    background do
      create(:ci_build, pipeline: pipeline, name: 'rspec')
      create(:ci_build, pipeline: pipeline, name: 'spinach')
    end

    scenario 'user visits a pipelines page', js: true do
      visit_merge_request(merge_request)
      page.within('.merge-request-tabs') { click_link 'Builds' }
      wait_for_ajax

      page.within('table.builds') do
        expect(page).to have_content 'rspec'
        expect(page).to have_content 'spinach'
      end

      expect(find_link('Cancel running')[:href])
        .to include fork_project.path_with_namespace
    end
  end

  def visit_merge_request(mr)
    visit namespace_project_merge_request_path(project.namespace,
                                               project, mr)
  end
end
