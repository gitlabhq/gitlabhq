# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_security do
    describe 'Pass dotenv variables to downstream via bridge' do
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
      let(:upstream_var) { Faker::Alphanumeric.alphanumeric(number: 8) }
      let(:group) { create(:group) }
      let(:upstream_project) { create(:project, group: group, name: 'upstream-project-with-bridge') }
      let(:downstream_project) { create(:project, group: group, name: 'downstream-project-with-bridge') }
      let!(:runner) { create(:group_runner, group: group, name: executor, tags: [executor]) }

      before do
        Flow::Login.sign_in
        add_ci_file(downstream_project, downstream_ci_file)
        add_ci_file(upstream_project, upstream_ci_file)
        upstream_project.visit!
        Flow::Pipeline.visit_latest_pipeline(status: 'Passed')
      end

      after do
        runner.remove_via_api!
        [upstream_project, downstream_project].each(&:remove_via_api!)
      end

      it 'runs the pipeline with composed config', :blocking,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348088' do
        Page::Project::Pipeline::Show.perform do |parent_pipeline|
          Support::Waiter.wait_until { parent_pipeline.has_linked_pipeline? }
          parent_pipeline.expand_linked_pipeline
          parent_pipeline.click_job('downstream_test')
        end

        Page::Project::Job::Show.perform do |show|
          expect(show).to have_passed(timeout: 360)
          expect(show.output).to have_content(upstream_var)
        end
      end

      private

      def add_ci_file(project, file)
        create(:commit, project: project, commit_message: 'Add config file', actions: [file])
      end

      def upstream_ci_file
        {
          action: 'create',
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            build:
              stage: build
              tags: ["#{executor}"]
              script:
                - for i in `seq 1 20`; do echo "VAR_$i=#{upstream_var}" >> variables.env; done;
              artifacts:
                reports:
                  dotenv: variables.env

            trigger:
              stage: deploy
              variables:
                PASSED_MY_VAR: "$VAR_#{rand(1..20)}"
              trigger: #{downstream_project.full_path}
          YAML
        }
      end

      def downstream_ci_file
        {
          action: 'create',
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            downstream_test:
              stage: test
              tags: ["#{executor}"]
              script:
                - echo $PASSED_MY_VAR
          YAML
        }
      end
    end
  end
end
