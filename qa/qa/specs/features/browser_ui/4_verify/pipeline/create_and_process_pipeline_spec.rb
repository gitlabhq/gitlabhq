# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_execution do
    describe 'Pipeline creation and processing' do
      let(:executor) { "qa-runner-#{Time.now.to_i}" }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-pipeline'
        end
      end

      let!(:runner) do
        Resource::ProjectRunner.fabricate! do |runner|
          runner.project = project
          runner.name = executor
          runner.tags = [executor]
        end
      end

      after do
        [runner, project].each(&:remove_via_api!)
      end

      it 'users creates a pipeline which gets processed', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348024' do
        Flow::Login.sign_in

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files(
            [
              {
                file_path: '.gitlab-ci.yml',
                content: <<~YAML
                  test-success:
                    tags:
                      - #{executor}
                    script: echo 'OK'

                  test-failure:
                    tags:
                      - #{executor}
                    script:
                      - echo 'FAILURE'
                      - exit 1

                  test-tags-mismatch:
                    tags:
                     - invalid
                    script: echo 'NOOP'

                  test-artifacts:
                    tags:
                      - #{executor}
                    script: mkdir my-artifacts; echo "CONTENTS" > my-artifacts/artifact.txt
                    artifacts:
                      paths:
                      - my-artifacts/

                  test-coverage-report:
                    tags:
                      - #{executor}
                    script: mkdir coverage; echo "CONTENTS" > coverage/cobertura.xml
                    artifacts:
                      reports:
                        coverage_report:
                          coverage_format: cobertura
                          path: coverage/cobertura.xml
                YAML
              }
            ]
          )
        end.project.visit!

        Flow::Pipeline.visit_latest_pipeline

        aggregate_failures do
          {
            'test-success': 'passed',
            'test-failure': 'failed',
            'test-tags-mismatch': 'pending',
            'test-artifacts': 'passed',
            'test-coverage-report': 'passed'
          }.each do |job, status|
            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.click_job(job)
            end

            Page::Project::Job::Show.perform do |show|
              expect(show).to have_status(status), "Expected job status to be #{status} but got #{show.status_badge} instead."
              show.click_element(:pipeline_path, Page::Project::Pipeline::Show)
            end
          end
        end
      end
    end
  end
end
