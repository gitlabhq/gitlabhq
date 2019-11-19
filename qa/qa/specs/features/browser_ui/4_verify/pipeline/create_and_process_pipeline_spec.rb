# frozen_string_literal: true

module QA
  context 'Verify', :orchestrated, :docker do
    describe 'Pipeline creation and processing' do
      let(:executor) { "qa-runner-#{Time.now.to_i}" }

      after do
        Service::DockerRun::GitlabRunner.new(executor).remove!
      end

      it 'users creates a pipeline which gets processed' do
        Flow::Login.sign_in

        project = Resource::Project.fabricate! do |project|
          project.name = 'project-with-pipelines'
          project.description = 'Project with CI/CD Pipelines.'
        end

        Resource::Runner.fabricate! do |runner|
          runner.project = project
          runner.name = executor
          runner.tags = %w[qa test]
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.file_name = '.gitlab-ci.yml'
          push.commit_message = 'Add .gitlab-ci.yml'
          push.file_content = <<~EOF
            test-success:
              tags:
                - qa
                - test
              script: echo 'OK'

            test-failure:
              tags:
                - qa
                - test
              script:
                - echo 'FAILURE'
                - exit 1

            test-tags:
              tags:
                - qa
                - docker
              script: echo 'NOOP'

            test-artifacts:
              tags:
                - qa
                - test
              script: mkdir my-artifacts; echo "CONTENTS" > my-artifacts/artifact.txt
              artifacts:
                paths:
                - my-artifacts/
          EOF
        end.project.visit!

        expect(page).to have_content('Add .gitlab-ci.yml')

        Page::Project::Menu.perform(&:click_ci_cd_pipelines)

        expect(page).to have_content('All 1')
        expect(page).to have_content('Add .gitlab-ci.yml')

        puts 'Waiting for the runner to process the pipeline'
        sleep 15 # Runner should process all jobs within 15 seconds.

        Page::Project::Pipeline::Index.perform(&:click_on_latest_pipeline)

        Page::Project::Pipeline::Show.perform do |pipeline|
          expect(pipeline).to be_running
          expect(pipeline).to have_build('test-success', status: :success)
          expect(pipeline).to have_build('test-failure', status: :failed)
          expect(pipeline).to have_build('test-tags', status: :pending)
          expect(pipeline).to have_build('test-artifacts', status: :success)
        end
      end
    end
  end
end
