# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, :requires_admin, product_group: :pipeline_insights do
    describe 'Artifacts' do
      context 'when locked' do
        let(:file_name) { 'artifact.txt' }
        let(:directory_name) { 'my_artifacts' }
        let(:executor) { "qa-runner-#{Time.now.to_i}" }

        let(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = 'project-with-locked-artifacts'
          end
        end

        let!(:runner) do
          Resource::ProjectRunner.fabricate! do |runner|
            runner.project = project
            runner.name = executor
            runner.tags = [executor]
          end
        end

        before do
          Flow::Login.sign_in
        end

        after do
          runner.remove_via_api!
        end

        it 'can be browsed', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348003' do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = project
            commit.commit_message = 'Add .gitlab-ci.yml'
            commit.add_files(
              [
                {
                  file_path: '.gitlab-ci.yml',
                  content: <<~YAML
                    test-artifacts:
                      tags:
                        - '#{executor}'
                      artifacts:
                        paths:
                          - '#{directory_name}'
                        expire_in: 1 sec
                      script:
                        - |
                          mkdir #{directory_name}
                          echo "CONTENTS" > #{directory_name}/#{file_name}
                  YAML
                }
              ]
            )
          end.project.visit!

          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('test-artifacts')
          end

          Page::Project::Job::Show.perform do |show|
            expect(show).to have_browse_button
            show.click_browse_button
          end

          Page::Project::Artifact::Show.perform do |show|
            show.go_to_directory(directory_name)
            expect(show).to have_content(file_name)
          end
        end
      end
    end
  end
end
