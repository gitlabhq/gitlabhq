# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_authoring do
    describe 'Pipeline with customizable variable' do
      let(:executor) { "qa-runner-#{SecureRandom.hex(6)}" }
      let(:pipeline_job_name) { 'customizable-variable' }
      let(:variable_custom_value) { 'Custom Foo' }
      let(:project) { create(:project, name: 'project-with-customizable-variable-pipeline') }
      let!(:runner) { create(:project_runner, project: project, name: executor, tags: [executor]) }

      let!(:commit) do
        create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
          {
            action: 'create',
            file_path: '.gitlab-ci.yml',
            content: <<~YAML
              variables:
                FOO:
                  value: "Default Foo"
                  description: "This is a description for the foo variable"
              #{pipeline_job_name}:
                tags:
                  - #{executor}
                script: echo "$FOO"
            YAML
          }
        ])
      end

      before do
        project.change_pipeline_variables_minimum_override_role('developer')

        Flow::Login.sign_in
        project.visit!
        Page::Project::Menu.perform(&:go_to_pipelines)
        Page::Project::Pipeline::Index.perform(&:click_run_pipeline_button)
      end

      after do
        runner.remove_via_api!
      end

      it 'manually creates a pipeline and uses the defined custom variable value',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/378975' do
        Page::Project::Pipeline::New.perform do |new|
          new.configure_variable(value: variable_custom_value)
          new.click_run_pipeline_button
        end

        Page::Project::Pipeline::Show.perform do |show|
          Support::Waiter.wait_until { show.passed? }

          show.click_job(pipeline_job_name)
        end

        Page::Project::Job::Show.perform do |show|
          expect(show.output).to have_content(variable_custom_value)
        end
      end
    end
  end
end
