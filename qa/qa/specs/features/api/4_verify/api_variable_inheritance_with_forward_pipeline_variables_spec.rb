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

        start_pipeline_via_api_with_variable

        Support::Waiter.wait_until(max_duration: 180, sleep_interval: 5) do
          upstream_pipeline.status == 'success'
        end

        Support::Waiter.wait_until(max_duration: 180, sleep_interval: 5) do
          downstream1_pipeline.pipeline_variables && child1_pipeline.pipeline_variables
        end
      end

      it(
        'is determined based on forward:pipeline_variables condition',
        :aggregate_failures,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/360745'
      ) do
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

      def start_pipeline_via_api_with_variable
        Resource::Pipeline.fabricate_via_api! do |pipeline|
          pipeline.project = upstream_project
          pipeline.variables = [{ key: key, value: value, variable_type: 'env_var' }]
        end

        Support::Waiter.wait_until { upstream_project.pipelines.size > 1 }
      end

      def upstream_pipeline
        Resource::Pipeline.fabricate_via_api! do |pipeline|
          pipeline.project = upstream_project
          pipeline.id = upstream_project.pipelines.first[:id]
        end
      end

      def child1_pipeline
        Resource::Pipeline.fabricate_via_api! do |pipeline|
          pipeline.project = upstream_project
          pipeline.id = upstream_pipeline.downstream_pipeline_id(bridge_name: 'child1_trigger')
        end
      end

      def child2_pipeline
        Resource::Pipeline.fabricate_via_api! do |pipeline|
          pipeline.project = upstream_project
          pipeline.id = upstream_pipeline.downstream_pipeline_id(bridge_name: 'child2_trigger')
        end
      end

      def downstream1_pipeline
        Resource::Pipeline.fabricate_via_api! do |pipeline|
          pipeline.project = downstream1_project
          pipeline.id = upstream_pipeline.downstream_pipeline_id(bridge_name: 'downstream1_trigger')
        end
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
                  pipeline_variables: true

            child2_trigger:
              stage: test
              trigger:
                include: .child2-ci.yml
                forward:
                  pipeline_variables: false

            # default behavior
            downstream1_trigger:
              stage: deploy
              trigger:
                project: #{downstream1_project.full_path}
          YAML
        }
      end
    end
  end
end
