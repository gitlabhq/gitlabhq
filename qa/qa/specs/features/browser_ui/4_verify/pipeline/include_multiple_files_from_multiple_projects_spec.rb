# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_authoring do
    describe 'Include multiple files from multiple projects' do
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
      let(:main_project) { create(:project, name: 'project-with-pipeline') }
      let(:project1) { create(:project, name: 'external-project-1') }
      let(:project2) { create(:project, name: 'external-project-2') }
      let!(:runner) { create(:project_runner, project: main_project, name: executor, tags: [executor]) }

      before do
        Flow::Login.sign_in

        add_included_files_for(main_project)
        add_included_files_for(project1)
        add_included_files_for(project2)
        add_ci_file_to_main_project

        main_project.visit_latest_pipeline
      end

      after do
        runner.remove_via_api!
      end

      it(
        'runs the pipeline with composed config',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396374'
      ) do
        Page::Project::Pipeline::Show.perform do |pipeline|
          aggregate_failures 'pipeline has all expected jobs' do
            expect(pipeline).to have_job('test_for_main')
            expect(pipeline).to have_job("test1_for_#{project1.full_path}")
            expect(pipeline).to have_job("test1_for_#{project2.full_path}")
            expect(pipeline).to have_job("test2_for_#{project1.full_path}")
            expect(pipeline).to have_job("test2_for_#{main_project.full_path}")
          end
        end
      end

      private

      def add_included_files_for(project)
        create(:commit, project: project, commit_message: 'Add files', actions: included_files(project))
      end

      def included_files(project)
        [
          {
            action: 'create',
            file_path: 'file1.yml',
            content: <<~YAML
              test1_for_#{project.full_path}:
                tags: ["#{executor}"]
                script: echo hello1
            YAML
          },
          {
            action: 'create',
            file_path: 'file2.yml',
            content: <<~YAML
              test2_for_#{project.full_path}:
                tags: ["#{executor}"]
                script: echo hello2
            YAML
          }
        ]
      end

      def add_ci_file_to_main_project
        create(:commit, project: main_project, commit_message: 'Add config file', actions: [main_ci_file])
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: main_project)
        Flow::Pipeline.wait_for_latest_pipeline_to_have_status(project: main_project, status: 'success')
      end

      def main_ci_file
        {
          action: 'create',
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            include:
              - project: #{project1.full_path}
                file: file1.yml
              - project: #{project2.full_path}
                file: file1.yml
              - project: #{project1.full_path}
                file: file2.yml
              - project: #{main_project.full_path}
                file: file2.yml

            test_for_main:
              tags: ["#{executor}"]
              script: echo hello
          YAML
        }
      end
    end
  end
end
