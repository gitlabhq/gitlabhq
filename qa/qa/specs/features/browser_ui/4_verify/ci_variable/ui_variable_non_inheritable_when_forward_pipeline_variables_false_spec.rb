# frozen_string_literal: true

module QA
  # TODO:
  # Remove FF :ci_trigger_forward_variables
  # when https://gitlab.com/gitlab-org/gitlab/-/issues/355572 is closed
  RSpec.describe 'Verify', :runner, feature_flag: {
    name: 'ci_trigger_forward_variables',
    scope: :global
  } do
    describe 'UI defined variable' do
      include_context 'variable inheritance test prep'

      before do
        add_ci_file(downstream1_project, [downstream1_ci_file])
        add_ci_file(downstream2_project, [downstream2_ci_file])
        add_ci_file(upstream_project, [upstream_ci_file, upstream_child1_ci_file, upstream_child2_ci_file])

        start_pipeline_with_variable
        Page::Project::Pipeline::Show.perform do |show|
          Support::Waiter.wait_until { show.passed? }
        end
      end

      it(
        'is not inheritable when forward:pipeline_variables is false',
        :aggregate_failures,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/358199'
      ) do
        visit_job_page('child1', 'child1_job')
        verify_job_log_does_not_show_variable_value

        page.go_back

        visit_job_page('downstream1', 'downstream1_job')
        verify_job_log_does_not_show_variable_value
      end

      it(
        'is not inheritable by default',
        :aggregate_failures,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/358200'
      ) do
        visit_job_page('child2', 'child2_job')
        verify_job_log_does_not_show_variable_value

        page.go_back

        visit_job_page('downstream2', 'downstream2_job')
        verify_job_log_does_not_show_variable_value
      end

      def upstream_ci_file
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            stages:
              - test
              - deploy

            child1_trigger:
              stage: test
              trigger:
                include: .child1-ci.yml
                forward:
                  pipeline_variables: false

            # default behavior
            child2_trigger:
              stage: test
              trigger:
                include: .child2-ci.yml

            downstream1_trigger:
              stage: deploy
              trigger:
                project: #{downstream1_project.full_path}
                forward:
                  pipeline_variables: false

            # default behavior
            downstream2_trigger:
              stage: deploy
              trigger:
                project: #{downstream2_project.full_path}
          YAML
        }
      end
    end
  end
end
