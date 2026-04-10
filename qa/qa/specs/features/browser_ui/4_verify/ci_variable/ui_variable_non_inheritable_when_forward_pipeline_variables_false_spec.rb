# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', feature_category: :pipeline_composition do
    describe 'UI defined variable' do
      include_context 'variable inheritance test prep'

      before do
        add_ci_file(downstream1_project, [downstream1_ci_file])
        add_ci_file(downstream2_project, [downstream2_ci_file])
        add_ci_file(upstream_project, [upstream_ci_file, upstream_child1_ci_file, upstream_child2_ci_file])

        start_pipeline_with_variable
        wait_for_pipelines
      end

      it(
        'is not inheritable when forward:pipeline_variables is false',
        :aggregate_failures,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/358199'
      ) do
        visit_job_page('child1', 'child1_job')
        verify_job_log_does_not_show_variable_value

        # Navigate back to the upstream pipeline show page explicitly rather than
        # relying on browser history, which can leave the pipeline graph mid-render.
        triggered_pipeline.visit!
        Page::Project::Pipeline::Show.perform do |show|
          show.wait_until { show.has_linked_pipeline?(title: downstream1_project.name) }
        end

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

        triggered_pipeline.visit!
        Page::Project::Pipeline::Show.perform do |show|
          show.wait_until { show.has_linked_pipeline?(title: 'downstream2') }
        end

        visit_job_page('downstream2', 'downstream2_job')
        verify_job_log_does_not_show_variable_value
      end

      def wait_for_pipelines
        Support::Waiter.wait_until(max_duration: 300, sleep_interval: 10) do
          triggered_pipeline&.status == 'success' &&
            child_pipeline('child1_trigger')&.status == 'success' &&
            child_pipeline('child2_trigger')&.status == 'success' &&
            downstream_pipeline(downstream1_project, 'downstream1_trigger')&.status == 'success' &&
            downstream_pipeline(downstream2_project, 'downstream2_trigger')&.status == 'success'
        end
      end

      def upstream_ci_file
        {
          action: 'create',
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            child1_trigger:
              trigger:
                include: .child1-ci.yml
                forward:
                  pipeline_variables: false

            # default behavior
            child2_trigger:
              trigger:
                include: .child2-ci.yml

            downstream1_trigger:
              trigger:
                project: #{downstream1_project.full_path}
                forward:
                  pipeline_variables: false

            # default behavior
            downstream2_trigger:
              trigger:
                project: #{downstream2_project.full_path}
          YAML
        }
      end
    end
  end
end
