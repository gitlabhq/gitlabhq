# frozen_string_literal: true

module QA
  # This context needs no runner.
  #
  # Main expectation:
  # When a pipeline is created it already carries its variables: forwarded ones are present,
  # non-forwarded ones are absent.
  #
  # Required dependencies:
  # - Each CI config defines a job that never runs, because a pipeline needs at least one to be created.
  # - Downstream pipelines are ready once the triggered pipeline succeeds, because a bridge without
  #   `trigger:strategy` succeeds as soon as it has created its downstream pipeline.
  RSpec.shared_context 'variable inheritance test prep' do
    let(:key) { 'TEST_VAR' }
    let(:value) { 'This is great!' }
    let(:random_string) { Faker::Alphanumeric.alphanumeric(number: 8) }
    let(:group) { create(:group, path: "group-for-variable-inheritance-#{random_string}") }

    let(:upstream_project) do
      create(:project,
        name: 'upstream-variable-inheritance',
        description: 'Project for pipeline with variable defined via UI - Upstream',
        group: group)
    end

    let(:downstream1_project) do
      create(:project,
        name: 'downstream1-variable-inheritance',
        description: 'Project for pipeline with variable defined via UI - Downstream',
        group: group)
    end

    let(:downstream2_project) do
      create(:project,
        name: 'downstream2-variable-inheritance',
        description: 'Project for pipeline with variable defined via UI - Downstream',
        group: group)
    end

    before do
      Flow::Login.sign_in
      upstream_project.change_pipeline_variables_minimum_override_role('developer')
      downstream1_project.change_pipeline_variables_minimum_override_role('developer')
      downstream2_project.change_pipeline_variables_minimum_override_role('developer')
    end

    def start_pipeline_with_variable
      Flow::Pipeline.wait_for_pipeline_creation_via_api(project: upstream_project)

      upstream_project.visit!
      Page::Project::Show.perform(&:close_dap_panel_if_exists)
      Page::Project::Menu.perform(&:go_to_pipelines)

      initial_pipeline_count = upstream_project.pipelines.size

      Page::Project::Pipeline::Index.perform(&:click_run_pipeline_button)
      Page::Project::Pipeline::New.perform do |new|
        new.configure_variable(key: key, value: value)
        new.click_run_pipeline_button
      end

      Support::Waiter.wait_until(max_duration: 300, sleep_interval: 10, message: 'Wait for new pipeline to appear') do
        current_pipelines = upstream_project.pipelines
        if current_pipelines.size > initial_pipeline_count
          newest_pipeline = current_pipelines.max_by { |p| p[:id].to_i }
          newest_id = newest_pipeline&.dig(:id)
          if newest_id
            @triggered_pipeline_id = newest_id
            true
          else
            false
          end
        else
          false
        end
      end
    end

    def wait_for_triggered_pipeline_to_succeed
      Support::Waiter.wait_until(
        max_duration: 120,
        sleep_interval: 5,
        message: 'Wait for trigger jobs to create their downstream pipelines'
      ) do
        triggered_pipeline&.status == 'success'
      end
    end

    def add_ci_file(project, files)
      create(:commit, project: project, commit_message: 'Add CI config file', actions: files)
    end

    def expect_pipeline_to_inherit_variable(pipeline)
      expect(pipeline).to have_variable(key: key, value: value),
        "Expected to find `{key: '#{key}', value: '#{value}'}` but got #{pipeline.pipeline_variables}"
    end

    def expect_pipeline_not_to_inherit_variable(pipeline)
      expect(pipeline).to have_no_variable(key: key, value: value),
        "Did not expect to find `{key: '#{key}', value: '#{value}'}` but got #{pipeline.pipeline_variables}"
    end

    def triggered_pipeline
      raise 'Triggered pipeline ID not set' unless @triggered_pipeline_id

      create(:pipeline, project: upstream_project, id: @triggered_pipeline_id)
    end

    def downstream_pipeline(project, bridge_name)
      id = triggered_pipeline.downstream_pipeline_id(bridge_name: bridge_name)
      return unless id

      create(:pipeline, project: project, id: id)
    end

    def child_pipeline(bridge_name)
      downstream_pipeline(upstream_project, bridge_name)
    end

    def upstream_child1_ci_file
      {
        action: 'create',
        file_path: '.child1-ci.yml',
        content: <<~YAML
          child1_job:
            stage: test
            script:
              - echo $TEST_VAR
              - echo Done!
        YAML
      }
    end

    def upstream_child2_ci_file
      {
        action: 'create',
        file_path: '.child2-ci.yml',
        content: <<~YAML
          child2_job:
            stage: test
            script:
              - echo $TEST_VAR
              - echo Done!
        YAML
      }
    end

    def downstream1_ci_file
      {
        action: 'create',
        file_path: '.gitlab-ci.yml',
        content: <<~YAML
          downstream1_job:
            stage: deploy
            script:
              - echo $TEST_VAR
              - echo Done!
        YAML
      }
    end

    def downstream2_ci_file
      {
        action: 'create',
        file_path: '.gitlab-ci.yml',
        content: <<~YAML
          downstream2_job:
            stage: deploy
            script:
              - echo $TEST_VAR
              - echo Done!
        YAML
      }
    end
  end
end
