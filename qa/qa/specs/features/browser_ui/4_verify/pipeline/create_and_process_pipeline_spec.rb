# frozen_string_literal: true

module QA
  context 'Verify', :docker, quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/issues/202149', type: :flaky } do
    describe 'Pipeline creation and processing' do
      let(:executor) { "qa-runner-#{Time.now.to_i}" }
      let(:max_wait) { 30 }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-pipeline'
        end
      end

      before do
        Resource::Runner.fabricate! do |runner|
          runner.project = project
          runner.name = executor
          runner.tags = [executor]
        end
      end

      after do
        Service::DockerRun::GitlabRunner.new(executor).remove!
      end

      it 'users creates a pipeline which gets processed', :smoke do
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

                  test-tags:
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
                YAML
              }
            ]
          )
        end.project.visit!

        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:click_on_latest_pipeline)

        Page::Project::Pipeline::Show.perform do |pipeline|
          expect(pipeline).to be_running(wait: max_wait)
          expect(pipeline).to have_build('test-success', status: :success, wait: max_wait)
          expect(pipeline).to have_build('test-failure', status: :failed, wait: max_wait)
          expect(pipeline).to have_build('test-tags', status: :pending, wait: max_wait)
          expect(pipeline).to have_build('test-artifacts', status: :success, wait: max_wait)
        end
      end
    end
  end
end
