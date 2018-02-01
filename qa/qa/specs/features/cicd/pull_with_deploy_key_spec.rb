module QA
  feature 'pull codes with a deploy key', :core, :docker do
    let(:runner_name) { "qa-runner-#{Time.now.to_i}" }

    after do
      Service::Runner.new(runner_name).remove!
    end

    scenario 'user pushes .gitlab-ci.yml to the repository' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      project = Factory::Resource::Project.fabricate! do |resource|
        resource.name = 'cicd-pull-with-deploy-key'
      end

      Factory::Resource::Runner.fabricate! do |runner|
        runner.project = project
        runner.name = runner_name
        runner.tags = %w[qa docker]
        runner.executor = 'shell'
        runner.image = 'gitlab/gitlab-runner:ubuntu'
      end

      key = Runtime::RSAKey.new

      Factory::Resource::DeployKey.fabricate! do |resource|
        resource.project = project
        resource.title = 'deploy key title'
        resource.key = key.public_key
      end

      Factory::Resource::SecretVariable.fabricate! do |resource|
        resource.project = project
        resource.key = 'DEPLOY_KEY'
        resource.value = key.to_pem
      end

      project.visit!

      repository_url = Page::Project::Show.act do
        choose_repository_clone_ssh
        repository_location
      end

      gitlab_ci =
        <<~YAML
          cat-config:
            script:
              - eval $(ssh-agent -s)
              - echo "$DEPLOY_KEY" | tr -d '\\r' | ssh-add - > /dev/null
              - git clone #{repository_url}
              - cat #{project.name}/.gitlab-ci.yml
            tags:
              - qa
              - docker
        YAML

      Factory::Repository::Push.fabricate! do |push|
        push.project = project
        push.file_name = '.gitlab-ci.yml'
        push.commit_message = 'Add .gitlab-ci.yml'
        push.file_content = gitlab_ci
      end

      Page::Project::Show.act { wait_for_push }
      Page::Menu::Side.act { click_ci_cd_pipelines }

      Page::Project::Pipeline::Index.act do
        wait_for_latest_pipeline
        go_to_latest_pipeline
      end

      Page::Project::Pipeline::Show.act do
        go_to_first_job
      end

      Page::Project::Job::Show.perform do |job|
        expect(job.output).to include(gitlab_ci.tr("\n", ' '))
      end
    end
  end
end
