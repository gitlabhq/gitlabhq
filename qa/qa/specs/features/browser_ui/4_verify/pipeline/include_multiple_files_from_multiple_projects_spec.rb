# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_authoring, feature_flag: {
    name: 'ci_batch_project_includes_context',
    scope: :global
  } do
    describe 'Include multiple files from multiple projects' do
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }

      let(:main_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-pipeline'
        end
      end

      let(:project1) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'external-project-1'
        end
      end

      let(:project2) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'external-project-2'
        end
      end

      let!(:runner) do
        Resource::ProjectRunner.fabricate! do |runner|
          runner.project = main_project
          runner.name = executor
          runner.tags = [executor]
        end
      end

      def before_do
        Flow::Login.sign_in

        add_included_files_for(main_project)
        add_included_files_for(project1)
        add_included_files_for(project2)
        add_main_ci_file(main_project)

        main_project.visit!
        Flow::Pipeline.visit_latest_pipeline(status: 'passed')
      end

      after do
        runner.remove_via_api!
      end

      context 'when FF is on', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396374' do
        before do
          Runtime::Feature.enable(:ci_batch_project_includes_context, project: main_project)
          sleep 60

          before_do
        end

        it 'runs the pipeline with composed config' do
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
      end

      context 'when FF is off', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396375' do
        before do
          Runtime::Feature.disable(:ci_batch_project_includes_context, project: main_project)
          sleep 60

          before_do
        end

        it 'runs the pipeline with composed config' do
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
      end

      private

      def add_included_files_for(project)
        files = [
          {
            file_path: 'file1.yml',
            content: <<~YAML
              test1_for_#{project.full_path}:
                tags: ["#{executor}"]
                script: echo hello1
            YAML
          },
          {
            file_path: 'file2.yml',
            content: <<~YAML
              test2_for_#{project.full_path}:
                tags: ["#{executor}"]
                script: echo hello2
            YAML
          }
        ]

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add files'
          commit.add_files(files)
        end
      end

      def add_main_ci_file(project)
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add config file'
          commit.add_files([main_ci_file])
        end
      end

      def main_ci_file
        {
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
