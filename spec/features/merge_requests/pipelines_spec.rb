require 'spec_helper'

feature 'Pipelines for Merge Requests', :js do
  describe 'pipeline tab' do
    given(:user) { create(:user) }
    given(:merge_request) { create(:merge_request) }
    given(:project) { merge_request.target_project }

    before do
      project.team << [user, :master]
      sign_in user
    end

    context 'with pipelines' do
      let!(:pipeline) do
        create(:ci_empty_pipeline,
               project: merge_request.source_project,
               ref: merge_request.source_branch,
               sha: merge_request.diff_head_sha)
      end

      before do
        visit project_merge_request_path(project, merge_request)
      end

      scenario 'user visits merge request pipelines tab' do
        page.within('.merge-request-tabs') do
          click_link('Pipelines')
        end
        wait_for_requests

        expect(page).to have_selector('.stage-cell')
      end
    end

    context 'without pipelines' do
      before do
        visit project_merge_request_path(project, merge_request)
      end

      scenario 'user visits merge request page' do
        page.within('.merge-request-tabs') do
          expect(page).to have_no_link('Pipelines')
        end
      end
    end
  end

  describe 'race condition' do
    given(:project) { create(:project, :repository) }
    given(:user) { create(:user) }
    given(:build_push_data) { { ref: 'feature', checkout_sha: TestEnv::BRANCH_SHA['feature'] } }

    given(:merge_request_params) do
      { "source_branch" => "feature", "source_project_id" => project.id,
        "target_branch" => "master", "target_project_id" => project.id, "title" => "A" }
    end

    background do
      project.add_master(user)
      sign_in user
    end

    context 'when pipeline and merge request were created simultaneously' do
      background do
        stub_ci_pipeline_to_return_yaml_file

        threads = []

        threads << Thread.new do
          @merge_request = MergeRequests::CreateService.new(project, user, merge_request_params).execute
        end

        threads << Thread.new do
          @pipeline = Ci::CreatePipelineService.new(project, user, build_push_data).execute(:push)
        end

        threads.each { |thr| thr.join }
      end

      scenario 'user sees pipeline in merge request widget' do
        visit project_merge_request_path(project, @merge_request)

        expect(page.find(".ci-widget")).to have_content(TestEnv::BRANCH_SHA['feature'])
        expect(page.find(".ci-widget")).to have_content("##{@pipeline.id}")
      end
    end
  end
end
