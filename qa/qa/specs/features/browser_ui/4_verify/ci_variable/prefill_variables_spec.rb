# frozen_string_literal: true

module QA
  RSpec.describe 'Verify' do
    describe 'Pipeline with prefill variables', feature_flag: {
      name: :run_pipeline_graphql,
      scope: :global
    } do
      let(:prefill_variable_description1) { Faker::Lorem.sentence }
      let(:prefill_variable_value1) { Faker::Lorem.word }
      let(:prefill_variable_value5) { Faker::Lorem.word }
      let(:prefill_variable_description2) { Faker::Lorem.sentence }
      let(:prefill_variable_description5) { Faker::Lorem.sentence }
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-prefill-variables'
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
                  variables:
                    TEST1:
                      value: #{prefill_variable_value1}
                      description: #{prefill_variable_description1}
                    TEST2:
                      description: #{prefill_variable_description2}
                    TEST3:
                      value: test 3 value
                    TEST4: test 4 value
                    TEST5:
                      value: "FOO"
                      options:
                        - #{prefill_variable_value5}
                        - "FOO"
                      description: #{prefill_variable_description5}
                  test:
                    script: echo "$FOO"
                YAML
              }
            ]
          )
        end
      end

      shared_examples 'pre-filled variables form' do |testcase|
        it 'shows only variables with description as prefill variables on the run pipeline page', testcase: testcase do
          Page::Project::Pipeline::New.perform do |new|
            aggregate_failures do
              expect(new).to have_field('Input variable key', with: 'TEST1')
              expect(new).to have_field('Input variable value', with: prefill_variable_value1)
              expect(new).to have_content(prefill_variable_description1)

              expect(new).to have_field('Input variable key', with: 'TEST2')
              expect(new).to have_field('Input variable value', with: '')
              expect(new).to have_content(prefill_variable_description2)

              expect(new).not_to have_field('Input variable key', with: 'TEST3')
              expect(new).not_to have_field('Input variable key', with: 'TEST4')

              # Legacy and GQL app will render the variable field differently
              expect(new).to have_field('Input variable key', with: 'TEST5')
              expect(new).to have_content(prefill_variable_description5)
            end
          end
        end
      end

      # TODO: Clean up tests when run_pipeline_graphql is enabled
      # Issue https://gitlab.com/gitlab-org/gitlab/-/issues/372310
      context 'with feature flag disabled' do
        before do
          Flow::Login.sign_in
          project.visit!

          # Navigate to Run Pipeline page
          Page::Project::Menu.perform(&:click_ci_cd_pipelines)
          Page::Project::Pipeline::Index.perform(&:click_run_pipeline_button)

          # Sometimes the variables will not be prefilled because of reactive cache so we revisit the page again.
          # TODO: Investigate alternatives to deal with cache implementation
          # Issue https://gitlab.com/gitlab-org/gitlab/-/issues/381233
          page.refresh
        end

        it_behaves_like 'pre-filled variables form', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/371204'

        it 'does not prefill dropdown variables but renders them as input fields',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/383819' do
          Page::Project::Pipeline::New.perform do |new|
            expect(new.has_variable_dropdown?).to be(false)
            expect(new).to have_field('Input variable value', with: 'FOO')
          end
        end
      end

      context 'with feature flag enabled' do
        before do
          Runtime::Feature.enable(:run_pipeline_graphql)
          sleep 30

          Flow::Login.sign_in
          project.visit!

          # Navigate to Run Pipeline page
          Page::Project::Menu.perform(&:click_ci_cd_pipelines)
          Page::Project::Pipeline::Index.perform(&:click_run_pipeline_button)

          # Sometimes the variables will not be prefilled because of reactive cache so we revisit the page again.
          # TODO: Investigate alternatives to deal with cache implementation
          # Issue https://gitlab.com/gitlab-org/gitlab/-/issues/381233
          page.refresh
        end

        after do
          Runtime::Feature.disable(:run_pipeline_graphql)
          sleep 30
        end

        it_behaves_like 'pre-filled variables form', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/378977'

        it 'shows dropdown for variables with description, value, and options defined',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/383820' do
          Page::Project::Pipeline::New.perform do |new|
            aggregate_failures do
              expect(new.variable_dropdown).to have_text('FOO')

              new.click_variable_dropdown

              expect(new.variable_dropdown_item_with_index(0)).to have_text(prefill_variable_value5)
              expect(new.variable_dropdown_item_with_index(1)).to have_text('FOO')
            end
          end
        end
      end
    end
  end
end
