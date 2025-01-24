# frozen_string_literal: true

module QA
  RSpec.describe 'Verify' do
    describe 'Include local config file paths with wildcard', product_group: :pipeline_authoring do
      let(:project) { create(:project, name: 'project-with-pipeline') }

      before do
        Flow::Login.sign_in
        add_files_to_project
        project.visit_latest_pipeline
      end

      it 'runs the pipeline with composed config',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348002' do
        Page::Project::Pipeline::Show.perform do |pipeline|
          aggregate_failures 'pipeline has all expected jobs' do
            expect(pipeline).to have_job('build')
            expect(pipeline).to have_job('test')
            expect(pipeline).not_to have_job('deploy')
          end
        end
      end

      private

      def add_files_to_project
        create(:commit, project: project, commit_message: 'Add CI and local files', actions: [
          build_config_file, test_config_file, non_detectable_file, main_ci_file
        ])
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
      end

      def main_ci_file
        {
          action: 'create',
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            include: 'configs/*.yml'
          YAML
        }
      end

      def build_config_file
        {
          action: 'create',
          file_path: 'configs/builds.yml',
          content: <<~YAML
            build:
              stage: build
              script: echo build
          YAML
        }
      end

      def test_config_file
        {
          action: 'create',
          file_path: 'configs/tests.yml',
          content: <<~YAML
            test:
              stage: test
              script: echo test
          YAML
        }
      end

      def non_detectable_file
        {
          action: 'create',
          file_path: 'configs/not_included.yaml', # we only include `*.yml` not `*.yaml`
          content: <<~YAML
            deploy:
              stage: deploy
              script: echo deploy
          YAML
        }
      end
    end
  end
end
