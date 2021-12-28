# frozen_string_literal: true

module QA
  RSpec.describe 'Verify' do
    describe 'Update CI file with pipeline editor' do
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
                  test_job:
                    script:
                      - echo "Simple test!"
                YAML
              }
            ]
          )
        end
      end

      before do
        Flow::Login.sign_in
        project.visit!
        Page::Project::Menu.perform(&:go_to_pipeline_editor)
      end

      after do
        project.remove_via_api!
      end

      it 'creates new pipeline and target branch', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/349005' do
        Page::Project::PipelineEditor::Show.perform do |show|
          show.write_to_editor(random_test_string)
          show.set_target_branch(random_test_string)
          show.submit_changes

          aggregate_failures do
            expect(show.target_branch_name).to eq(random_test_string)
            expect(show.current_branch).to eq(random_test_string)
            expect(show.editing_content).to have_content(random_test_string)
            expect(show.pipeline_id).to eq(project.pipelines.first[:id])
          end
        end

        expect(project).to have_branch(random_test_string)
      end
    end
  end
end
