# frozen_string_literal: true

module QA
  RSpec.describe 'Verify' do
    # TODO: Remove flag toggle when FF :simulate_pipeline is removed
    # Flag rollout issue https://gitlab.com/gitlab-org/gitlab/-/issues/364257
    describe 'Pipeline editor', :reliable, feature_flag: {
      name: :simulate_pipeline,
      scope: :global
    } do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'pipeline-editor-project'
        end
      end

      let!(:commit) do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files(
            [
              {
                file_path: '.gitlab-ci.yml',
                content: <<~YAML
                  stages:
                    - stage1
                    - stage2

                  job1:
                    stage: stage1
                    script: echo 'Done.'

                  job2:
                    stage: stage2
                    script: echo 'Done.'
                YAML
              }
            ]
          )
        end
      end

      before do
        # Make sure a pipeline is created before visiting pipeline editor page.
        # Otherwise, test might timeout before the page finishing fetching pipeline status.
        Support::Waiter.wait_until { project.pipelines.present? }

        Flow::Login.sign_in
        project.visit!
        Page::Project::Menu.perform(&:go_to_pipeline_editor)
      end

      # TODO: Update test cases titles and descriptions to not refer to FF status after FF is removed
      describe 'with feature flag simulate_pipeline enabled' do
        before(:context) do
          Runtime::Feature.enable(:simulate_pipeline)

          # Due to known delay in FF switching, sleep here
          sleep(60)
        end

        context 'when CI has valid syntax' do
          it(
            'shows valid validations',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/368332'
          ) do
            Page::Project::PipelineEditor::Show.perform do |show|
              aggregate_failures do
                expect(show.ci_syntax_validate_message).to have_content('Pipeline syntax is correct')

                show.go_to_visualize_tab
                { stage1: 'job1', stage2: 'job2' }.each_pair do |stage, job|
                  expect(show).to have_stage(stage), "Pipeline graph does not have stage #{stage}."
                  expect(show).to have_job(job), "Pipeline graph does not have job #{job}."
                end

                show.go_to_validate_tab
                show.simulate_pipeline
                expect(show.tab_alert_title).to have_content('Simulation completed successfully')

                show.go_to_view_merged_yaml_tab
                expect(show).to have_source_editor
              end
            end
          end
        end

        context 'when CI has invalid syntax' do
          it(
            'shows invalid validations',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/368333'
          ) do
            invalid_msg = 'syntax is invalid'

            Page::Project::PipelineEditor::Show.perform do |show|
              show.write_to_editor(SecureRandom.hex(10))

              aggregate_failures do
                show.go_to_visualize_tab
                expect(show.tab_alert_message).to have_content(invalid_msg)

                show.go_to_validate_tab
                show.simulate_pipeline
                expect(show.tab_alert_title).to have_content('Pipeline simulation completed with errors')

                show.go_to_view_merged_yaml_tab
                expect(show.tab_alert_message).to have_content(invalid_msg)

                expect(show.ci_syntax_validate_message).to have_content('CI configuration is invalid')
              end
            end
          end
        end
      end

      # TODO: remove this block when when FF :simulate_pipeline is removed
      # TODO: Also archive the old test cases since they will no longer be relevant
      describe 'with feature flag simulate_pipeline disabled' do
        before(:context) do
          Runtime::Feature.disable(:simulate_pipeline)

          # Due to known delay in FF switching, sleep here
          sleep(60)
        end

        context 'when CI has valid syntax' do
          it(
            'shows valid validations',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/349128'
          ) do
            Page::Project::PipelineEditor::Show.perform do |show|
              aggregate_failures do
                expect(show.ci_syntax_validate_message).to have_content('Pipeline syntax is correct')

                show.go_to_visualize_tab
                { stage1: 'job1', stage2: 'job2' }.each_pair do |stage, job|
                  expect(show).to have_stage(stage), "Pipeline graph does not have stage #{stage}."
                  expect(show).to have_job(job), "Pipeline graph does not have job #{job}."
                end

                show.go_to_lint_tab
                expect(show.tab_alert_message).to have_content('Syntax is correct')

                show.go_to_view_merged_yaml_tab
                expect(show).to have_source_editor
              end
            end
          end
        end

        context 'when CI has invalid syntax' do
          it(
            'shows invalid validations',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/349129'
          ) do
            invalid_msg = 'syntax is invalid'

            Page::Project::PipelineEditor::Show.perform do |show|
              show.write_to_editor(SecureRandom.hex(10))

              aggregate_failures do
                show.go_to_visualize_tab
                expect(show.tab_alert_message).to have_content(invalid_msg)

                show.go_to_lint_tab
                expect(show.tab_alert_message).to have_content('Syntax is incorrect')

                show.go_to_view_merged_yaml_tab
                expect(show.tab_alert_message).to have_content(invalid_msg)

                expect(show.ci_syntax_validate_message).to have_content('CI configuration is invalid')
              end
            end
          end
        end
      end
    end
  end
end
