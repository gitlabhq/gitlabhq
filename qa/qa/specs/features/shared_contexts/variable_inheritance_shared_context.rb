# frozen_string_literal: true

module QA
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
    let!(:runner) { create(:group_runner, group: group, name: random_string, tags: [random_string]) }

    before do
      Flow::Login.sign_in
      upstream_project.change_pipeline_variables_minimum_override_role('developer')
      downstream1_project.change_pipeline_variables_minimum_override_role('developer')
      downstream2_project.change_pipeline_variables_minimum_override_role('developer')
    end

    after do
      runner.remove_via_api!
    end

    def start_pipeline_with_variable
      upstream_project.visit!
      Flow::Pipeline.wait_for_latest_pipeline
      Page::Project::Pipeline::Index.perform(&:click_run_pipeline_button)
      Page::Project::Pipeline::New.perform do |new|
        new.configure_variable(key: key, value: value)
        new.click_run_pipeline_button
      end
    end

    def wait_for_pipelines
      Support::Waiter.wait_until(max_duration: 300, sleep_interval: 10) do
        upstream_pipeline.status == 'success' &&
          downstream_pipeline(downstream1_project, 'downstream1_trigger').status == 'success'
      end
    end

    def add_ci_file(project, files)
      create(:commit, project: project, commit_message: 'Add CI config file', actions: files)
    end

    def visit_job_page(pipeline_title, job_name)
      Page::Project::Pipeline::Show.perform do |show|
        show.expand_child_pipeline(title: pipeline_title)
        show.click_job(job_name)
      end
    end

    def verify_job_log_shows_variable_value
      Page::Project::Job::Show.perform do |show|
        show.wait_until { show.successful? }
        expect(show.output).to have_content(value)
      end
    end

    def verify_job_log_does_not_show_variable_value
      Page::Project::Job::Show.perform do |show|
        show.wait_until { show.successful? }
        expect(show.output).to have_no_content(value)
      end
    end

    def upstream_pipeline
      create(:pipeline, project: upstream_project, id: upstream_project.pipelines.first[:id])
    end

    def downstream_pipeline(project, bridge_name)
      create(:pipeline, project: project, id: upstream_pipeline.downstream_pipeline_id(bridge_name: bridge_name))
    end

    def upstream_child1_ci_file
      {
        action: 'create',
        file_path: '.child1-ci.yml',
        content: <<~YAML
          child1_job:
            stage: test
            tags: ["#{random_string}"]
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
            tags: ["#{random_string}"]
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
            tags: ["#{random_string}"]
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
            tags: ["#{random_string}"]
            script:
              - echo $TEST_VAR
              - echo Done!
        YAML
      }
    end
  end
end
