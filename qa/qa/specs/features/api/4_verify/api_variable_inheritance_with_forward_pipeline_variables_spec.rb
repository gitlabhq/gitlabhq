# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', feature_category: :pipeline_composition do
    describe 'Pipeline API defined variable inheritance' do
      include_context 'variable inheritance test prep'

      before do
        add_ci_file(downstream1_project, [downstream1_ci_file])
        add_ci_file(upstream_project, [upstream_ci_file, upstream_child1_ci_file, upstream_child2_ci_file])
      end

      it(
        'is determined based on forward:pipeline_variables condition',
        :aggregate_failures
      ) do
        start_pipeline_via_api_with_variable
        wait_for_triggered_pipeline_to_succeed

        # When forward:pipeline_variables is true
        expect_pipeline_to_inherit_variable(child_pipeline('child1_trigger'))

        # When forward:pipeline_variables is false
        expect_pipeline_not_to_inherit_variable(child_pipeline('child2_trigger'))

        # When forward:pipeline_variables is default
        expect_pipeline_not_to_inherit_variable(
          downstream_pipeline(downstream1_project, 'downstream1_trigger')
        )
      end

      def start_pipeline_via_api_with_variable
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: upstream_project)

        new_pipeline = create(:pipeline, project: upstream_project,
          variables: [{ key: key, value: value, variable_type: 'env_var' }])
        @triggered_pipeline_id = new_pipeline.id
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
