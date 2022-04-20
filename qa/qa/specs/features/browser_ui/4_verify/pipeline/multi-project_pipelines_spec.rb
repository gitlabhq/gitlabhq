# frozen_string_literal: true

module QA
  RSpec.describe 'Verify' do
    describe 'Multi-project pipelines' do
      let(:downstream_job_name) { 'downstream_job' }
      let(:executor) { "qa-runner-#{SecureRandom.hex(4)}" }
      let!(:group) { Resource::Group.fabricate_via_api! }

      let(:upstream_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.group = group
          project.name = 'upstream-project'
        end
      end

      let(:downstream_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.group = group
          project.name = 'downstream-project'
        end
      end

      let!(:runner) do
        Resource::Runner.fabricate_via_api! do |runner|
          runner.token = group.reload!.runners_token
          runner.name = executor
          runner.tags = [executor]
        end
      end

      before do
        add_ci_file(downstream_project, downstream_ci_file)
        add_ci_file(upstream_project, upstream_ci_file)

        Flow::Login.sign_in
        upstream_project.visit!
        Flow::Pipeline.visit_latest_pipeline(status: 'passed')
      end

      after do
        runner.remove_via_api!
        [upstream_project, downstream_project].each(&:remove_via_api!)
      end

      it(
        'creates a multi-project pipeline',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/358064'
      ) do
        Page::Project::Pipeline::Show.perform do |show|
          expect(show).to have_passed
          expect(show).not_to have_job(downstream_job_name)

          show.expand_linked_pipeline

          expect(show).to have_job(downstream_job_name)
        end
      end

      private

      def add_ci_file(project, file)
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add CI config file'
          commit.add_files([file])
        end
      end

      def upstream_ci_file
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            stages:
             - test
             - deploy

            job1:
              stage: test
              tags: ["#{executor}"]
              script: echo 'done'

            staging:
              stage: deploy
              trigger:
                project: #{downstream_project.path_with_namespace}
                strategy: depend
          YAML
        }
      end

      def downstream_ci_file
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            "#{downstream_job_name}":
              stage: test
              tags: ["#{executor}"]
              script: echo 'done'
          YAML
        }
      end
    end
  end
end
