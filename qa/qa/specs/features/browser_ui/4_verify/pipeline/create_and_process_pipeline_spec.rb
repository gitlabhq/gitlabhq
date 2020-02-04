# frozen_string_literal: true

module QA
  context 'Verify', :docker do
    describe 'Pipeline creation and processing' do
      let(:executor) { "qa-runner-#{Time.now.to_i}" }

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
          expect(pipeline).to be_running(wait: 30)
          expect(pipeline).to have_build('test-success', status: :success)
          expect(pipeline).to have_build('test-failure', status: :failed)
          expect(pipeline).to have_build('test-tags', status: :pending)
          expect(pipeline).to have_build('test-artifacts', status: :success)
        end
      end
    end
  end
end
