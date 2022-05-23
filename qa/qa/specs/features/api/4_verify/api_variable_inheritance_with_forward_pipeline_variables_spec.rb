# frozen_string_literal: true

module QA
  # TODO:
  # Remove FF :ci_trigger_forward_variables
  # when https://gitlab.com/gitlab-org/gitlab/-/issues/355572 is closed
  RSpec.describe 'Verify', :runner, feature_flag: {
    name: 'ci_trigger_forward_variables',
    scope: :global
  } do
    describe 'Pipeline API defined variable inheritance' do
      include_context 'variable inheritance test prep'

      before do
        add_ci_file(downstream1_project, [downstream1_ci_file])
        add_ci_file(upstream_project, [upstream_ci_file, upstream_child1_ci_file, upstream_child2_ci_file])
      end

      it(
        'is determined based on forward:pipeline_variables condition',
        :aggregate_failures,
        :transient,
        issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/361400',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/360745'
      ) do
        # Due to long runtime, using 5 times trials instead of default 10 times
        5.times do |i|
          QA::Runtime::Logger.info("API pipeline variable inheritance transient bug test - Trial #{i + 1}")
          start_pipeline_via_api_with_variable(i + 1)
          wait_for_pipelines

          # Is inheritable when true
          expect(child1_pipeline).to have_variable(key: key, value: value),
                                     "Expected to find `{key: 'TEST_VAR', value: 'This is great!'}`" \
            " but got #{child1_pipeline.pipeline_variables}"

          # Is not inheritable when false
          expect(child2_pipeline).not_to have_variable(key: key, value: value),
                                         "Did not expect to find `{key: 'TEST_VAR', value: 'This is great!'}`" \
            " but got #{child2_pipeline.pipeline_variables}"

          # Is not inheritable by default
          expect(downstream1_pipeline).not_to have_variable(key: key, value: value),
                                              "Did not expect to find `{key: 'TEST_VAR', value: 'This is great!'}`" \
            " but got #{downstream1_pipeline.pipeline_variables}"
        end
      end

      def start_pipeline_via_api_with_variable(expected_size)
        # Wait for 1st or previous pipeline to finish
        Support::Waiter.wait_until do
          upstream_project.pipelines.size == expected_size && upstream_pipeline.status == 'success'
        end

        Resource::Pipeline.fabricate_via_api! do |pipeline|
          pipeline.project = upstream_project
          pipeline.variables = [{ key: key, value: value, variable_type: 'env_var' }]
        end

        # Wait for this pipeline to be created
        Support::Waiter.wait_until { upstream_project.pipelines.size > expected_size }
      end

      def upstream_ci_file
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            child1_trigger:
              trigger:
                include: .child1-ci.yml
                forward:
                  pipeline_variables: true

            child2_trigger:
              trigger:
                include: .child2-ci.yml
                forward:
                  pipeline_variables: false

            # default behavior
            downstream1_trigger:
              trigger:
                project: #{downstream1_project.full_path}
          YAML
        }
      end
    end
  end
end
