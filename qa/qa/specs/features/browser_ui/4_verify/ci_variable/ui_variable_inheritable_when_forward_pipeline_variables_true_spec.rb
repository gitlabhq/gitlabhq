# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_authoring do
    describe 'UI defined variable' do
      include_context 'variable inheritance test prep'

      before do
        add_ci_file(downstream1_project, [downstream1_ci_file])
        add_ci_file(upstream_project, [upstream_ci_file, upstream_child1_ci_file])

        start_pipeline_with_variable
        wait_for_pipelines
      end

      it(
        'is inheritable when forward:pipeline_variables is true',
        :aggregate_failures,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/358197'
      ) do
        visit_job_page('child1', 'child1_job')
        verify_job_log_shows_variable_value

        page.go_back

        visit_job_page('downstream1', 'downstream1_job')
        verify_job_log_shows_variable_value
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
                  pipeline_variables: true

            downstream1_trigger:
              trigger:
                project: #{downstream1_project.full_path}
                forward:
                  pipeline_variables: true
          YAML
        }
      end
    end
  end
end
