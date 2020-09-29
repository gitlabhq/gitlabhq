# frozen_string_literal: true

module QA
  RSpec.describe 'Verify' do
    describe 'Run pipeline', :requires_admin, :skip_live_env do
      # [TODO]: Developer to remove :requires_admin and :skip_live_env once FF is removed in https://gitlab.com/gitlab-org/gitlab/-/issues/229632

      context 'with web only rule' do
        let(:feature_flag) { :new_pipeline_form }
        let(:job_name) { 'test_job' }
        let(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = 'web-only-pipeline'
          end
        end

        let!(:ci_file) do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = project
            commit.commit_message = 'Add .gitlab-ci.yml'
            commit.add_files(
              [
                  {
                      file_path: '.gitlab-ci.yml',
                      content: <<~YAML
                        #{job_name}:
                          tags:
                            - #{project.name}
                          script: echo 'OK'
                          only:
                            - web
                      YAML
                  }
              ]
            )
          end
        end

        before do
          Runtime::Feature.enable(feature_flag) # [TODO]: Developer to remove when feature flag is removed
          Flow::Login.sign_in
          project.visit!
          Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        end

        after do
          Runtime::Feature.disable(feature_flag) # [TODO]: Developer to remove when feature flag is removed
        end

        it 'can trigger pipeline', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/946' do
          Page::Project::Pipeline::Index.perform do |index|
            expect(index).not_to have_pipeline # should not auto trigger pipeline
            index.click_run_pipeline_button
          end

          Page::Project::Pipeline::New.perform(&:click_run_pipeline_button)

          Page::Project::Pipeline::Show.perform do |pipeline|
            expect(pipeline).to have_job(job_name)
          end
        end
      end
    end
  end
end
