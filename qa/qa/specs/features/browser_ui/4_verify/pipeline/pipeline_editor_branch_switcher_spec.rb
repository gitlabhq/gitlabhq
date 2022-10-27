# frozen_string_literal: true

module QA
  RSpec.describe 'Verify' do
    describe 'Pipeline editor', product_group: :pipeline_authoring do
      let(:random_test_string) { SecureRandom.hex(10) }

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
                    - test

                  initialize:
                    stage: test
                    script:
                      - echo "I am now on branch #{project.default_branch}"
                YAML
              }
            ]
          )
        end
      end

      let!(:test_branch) do
        Resource::Repository::ProjectPush.fabricate! do |resource|
          resource.project = project
          resource.branch_name = random_test_string
          resource.file_name = '.gitlab-ci.yml'
          resource.file_content = <<~YAML
            stages:
              - test

            initialize:
              stage: test
              script:
                - echo "I am now on branch #{random_test_string}"
          YAML
        end
      end

      before do
        Flow::Login.sign_in
        project.visit!

        # Project push sometimes takes a while to complete
        # Making sure new branch is pushed successfully prior to interacting
        Support::Retrier.retry_until(max_duration: 15, sleep_interval: 3, reload_page: false, message: 'Ensuring project has branch') do
          project.has_branch?(random_test_string)
        end
      end

      after do
        project.remove_via_api!
      end

      it 'can switch branches and target branch field updates accordingly', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347661' do
        Page::Project::Menu.perform(&:go_to_pipeline_editor)
        Page::Project::PipelineEditor::Show.perform do |show|
          show.open_branch_selector_dropdown
          show.select_branch_from_dropdown(random_test_string)

          aggregate_failures do
            expect(show.source_branch_name).to eq(random_test_string), 'Branch field is not showing expected branch name.'
            expect(show.editing_content).to have_content(random_test_string), 'Editor content does not include expected test string.'
          end

          show.open_branch_selector_dropdown
          show.select_branch_from_dropdown(project.default_branch)

          aggregate_failures do
            expect(show.source_branch_name).to eq(project.default_branch), 'Branch field is not showing expected branch name.'
            expect(show.editing_content).to have_content(project.default_branch), 'Editor content does not include expected test string.'
          end
        end
      end
    end
  end
end
