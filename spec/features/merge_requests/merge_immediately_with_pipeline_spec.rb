require 'spec_helper'

feature 'Merge immediately', :feature, :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }

  let!(:merge_request) do
    create(:merge_request_with_diffs, source_project: project,
                                      author: user,
                                      title: 'Bug NS-04',
                                      head_pipeline: pipeline,
                                      source_branch: pipeline.ref)
  end

  let(:pipeline) do
    create(:ci_pipeline, project: project,
                         ref: 'master',
                         sha: project.repository.commit('master').id)
  end

  before do
    project.team << [user, :master]
  end

  context 'when there is active pipeline for merge request' do
    background do
      create(:ci_build, pipeline: pipeline)
    end

    before do
      sign_in user
      visit project_merge_request_path(merge_request.project, merge_request)
    end

    it 'enables merge immediately' do
      page.within '.mr-widget-body' do
        find('.dropdown-toggle').click

        Sidekiq::Testing.fake! do
          click_link 'Merge immediately'

          expect(find('.accept-merge-request.btn-info')).to have_content('Merge in progress')

          wait_for_requests
        end
      end
    end
  end
end
