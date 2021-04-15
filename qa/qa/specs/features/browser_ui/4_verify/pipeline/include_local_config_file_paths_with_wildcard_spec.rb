# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :requires_admin do
    describe 'Include local config file paths with wildcard' do
      let(:feature_flag) { :ci_wildcard_file_paths }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-pipeline'
        end
      end

      before do
        Runtime::Feature.enable(feature_flag)
        Flow::Login.sign_in
        add_files_to_project
        project.visit!
        Flow::Pipeline.visit_latest_pipeline
      end

      after do
        Runtime::Feature.disable(feature_flag)
        project.remove_via_api!
      end

      it 'runs the pipeline with composed config', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1757' do
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
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add CI and local files'
          commit.add_files([build_config_file, test_config_file, non_detectable_file, main_ci_file])
        end
      end

      def main_ci_file
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            include: 'configs/*.yml'
          YAML
        }
      end

      def build_config_file
        {
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
