# frozen_string_literal: true

module QA
  RSpec.describe 'Verify' do
    describe 'Run pipeline', :reliable, product_group: :pipeline_execution do
      context 'with web only rule' do
        let(:job_name) { 'test_job' }
        let(:project) { create(:project, name: 'web-only-pipeline') }
        let!(:ci_file) do
          create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
            {
              action: 'create',
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
          ])
        end

        before do
          Flow::Login.sign_in
          project.visit!
          Page::Project::Menu.perform(&:go_to_pipelines)
        end

        it 'can trigger pipeline', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348011' do
          Page::Project::Pipeline::Index.perform do |index|
            expect(index).to have_no_pipeline # should not auto trigger pipeline
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
