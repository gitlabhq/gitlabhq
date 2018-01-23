module QA
  feature 'CI/CD Pipelines', :core, :docker do
    let(:executor) { "qa-runner-#{Time.now.to_i}" }

    after do
      Service::Runner.new(executor).remove!
    end

    scenario 'user registers a new specific runner' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      Factory::Resource::Runner.fabricate! do |runner|
        runner.name = executor
      end

      Page::Project::Settings::CICD.perform do |settings|
        settings.refresh

        settings.expand_runners_settings do |page|
          expect(page).to have_content(executor)
          expect(page).to have_online_runner
        end
      end
    end

    scenario 'users creates a new pipeline' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      project = Factory::Resource::Project.fabricate! do |project|
        project.name = 'project-with-pipelines'
        project.description = 'Project with CI/CD Pipelines.'
      end

      Factory::Resource::Runner.fabricate! do |runner|
        runner.project = project
        runner.name = executor
        runner.tags = %w[qa test]
      end

      Factory::Repository::Push.fabricate! do |push|
        push.project = project
        push.file_name = '.gitlab-ci.yml'
        push.commit_message = 'Add .gitlab-ci.yml'
        push.file_content = <<~EOF
          echo-success-test:
            tags:
              - qa
              - test
            script: echo 'OK'

          echo-failure-test:
            tags:
              - qa
              - test
            script:
              - echo 'FAILURE'
              - exit 1

          echo-artifacts-test:
            tags:
              - qa
              - test
            script: echo "CONTENTS" > my-artifacts/artifact.txt
            artifacts:
              paths:
                - my-artifacts/
        EOF
      end

      Page::Project::Show.act { wait_for_push }

      expect(page).to have_content('Add .gitlab-ci.yml')
    end
  end
end
