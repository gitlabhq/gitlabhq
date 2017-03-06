require 'spec_helper'

feature 'Merge immediately', :feature, :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }

  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project,
                                      author: user,
                                      title: 'Bug NS-04')
  end

  let(:pipeline) do
    create(:ci_pipeline, project: project,
                         sha: merge_request.diff_head_sha,
                         ref: merge_request.source_branch)
  end

  before { project.team << [user, :master] }

  context 'when there is active pipeline for merge request' do
    background do
      create(:ci_build, pipeline: pipeline)
    end

    before do
      login_as user
      visit namespace_project_merge_request_path(merge_request.project.namespace, merge_request.project, merge_request)
    end

    it 'enables merge immediately' do
      page.within '.mr-widget-body' do
        find('.dropdown-toggle').click

        click_link 'Merge Immediately'

        expect(find('.js-merge-button')).to have_content('Merge in progress')
      end
    end
  end
end
