# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_authoring do
    describe 'Include multiple files from a project' do
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
      let(:expected_text) { Faker::Lorem.sentence }
      let(:unexpected_text) { Faker::Lorem.sentence }

      let(:project) { create(:project, name: 'project-with-pipeline-1') }
      let(:other_project) { create(:project, name: 'project-with-pipeline-2') }
      let!(:runner) { create(:project_runner, project: project, name: executor, tags: [executor]) }

      before do
        Flow::Login.sign_in
        add_included_files
        add_main_ci_file
        project.visit_latest_pipeline
      end

      after do
        runner.remove_via_api!
      end

      it 'runs the pipeline with composed config',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348087' do
        Page::Project::Pipeline::Show.perform do |pipeline|
          aggregate_failures 'pipeline has all expected jobs' do
            expect(pipeline).to have_job('build')
            expect(pipeline).to have_job('test')
            expect(pipeline).to have_job('deploy')
          end

          pipeline.click_job('test')
        end

        Page::Project::Job::Show.perform do |job|
          aggregate_failures 'main CI is not overridden' do
            expect(job.output).not_to have_content(unexpected_text.to_s)
            expect(job.output).to have_content(expected_text.to_s)
          end
        end
      end

      private

      def add_main_ci_file
        create(:commit, project: project, commit_message: 'Add config file', actions: [main_ci_file])
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
        Flow::Pipeline.wait_for_latest_pipeline_to_have_status(project: project, status: 'success')
      end

      def add_included_files
        create(:commit,
          project: other_project,
          commit_message: 'Add files',
          actions: [included_file_1, included_file_2])
      end

      def main_ci_file
        {
          action: 'create',
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            include:
              - project: #{other_project.full_path}
                file:
                  - file1.yml
                  - file2.yml

            build:
              stage: build
              tags: ["#{executor}"]
              script: echo 'build'

            test:
              stage: test
              tags: ["#{executor}"]
              script: echo "#{expected_text}"
          YAML
        }
      end

      def included_file_1
        {
          action: 'create',
          file_path: 'file1.yml',
          content: <<~YAML
            test:
              stage: test
              tags: ["#{executor}"]
              script: echo "#{unexpected_text}"
          YAML
        }
      end

      def included_file_2
        {
          action: 'create',
          file_path: 'file2.yml',
          content: <<~YAML
            deploy:
              stage: deploy
              tags: ["#{executor}"]
              script: echo 'deploy'
          YAML
        }
      end
    end
  end
end
