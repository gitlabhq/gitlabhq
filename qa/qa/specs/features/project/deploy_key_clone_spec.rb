require 'digest/sha1'

module QA
  feature 'cloning code using a deploy key', :core, :docker do
    let(:runner_name) { "qa-runner-#{Time.now.to_i}" }

    given(:project) do
      Factory::Resource::Project.fabricate! do |resource|
        resource.name = 'deploy-key-clone-project'
      end
    end

    after do
      Service::Runner.new(runner_name).remove!
    end

    keys = [
      Runtime::Key::RSA.new(2048),
      Runtime::Key::RSA.new(4096),
      Runtime::Key::RSA.new(8192),
      Runtime::Key::DSA.new,
      Runtime::Key::ECDSA.new(256),
      Runtime::Key::ECDSA.new(384),
      Runtime::Key::ECDSA.new(521),
      Runtime::Key::ED25519.new
    ]

    keys.each do |key|
      scenario "user sets up a deploy key with #{key.name}(#{key.bits}) to clone code using pipelines" do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }

        Factory::Resource::Runner.fabricate! do |resource|
          resource.project = project
          resource.name = runner_name
          resource.tags = %w[qa docker]
          resource.image = 'gitlab/gitlab-runner:ubuntu'
        end

        Factory::Resource::DeployKey.fabricate! do |resource|
          resource.project = project
          resource.title = 'deploy key title'
          resource.key = key.public_key
        end

        Factory::Resource::SecretVariable.fabricate! do |resource|
          resource.project = project
          resource.key = 'DEPLOY_KEY'
          resource.value = key.private_key
        end

        project.visit!

        repository_uri = Page::Project::Show.act do
          choose_repository_clone_ssh
          repository_location_uri
        end

        gitlab_ci = <<~YAML
          cat-config:
            script:
              - mkdir -p ~/.ssh
              - ssh-keyscan -p #{repository_uri.port} #{repository_uri.host} >> ~/.ssh/known_hosts
              - eval $(ssh-agent -s)
              - echo "$DEPLOY_KEY" | ssh-add -
              - git clone #{repository_uri.git_uri}
              - sha1sum #{project.name}/.gitlab-ci.yml
            tags:
              - qa
              - docker
        YAML

        Factory::Repository::Push.fabricate! do |resource|
          resource.project = project
          resource.file_name = '.gitlab-ci.yml'
          resource.commit_message = 'Add .gitlab-ci.yml'
          resource.file_content = gitlab_ci
        end

        sha1sum = Digest::SHA1.hexdigest(gitlab_ci)

        Page::Project::Show.act { wait_for_push }
        Page::Menu::Side.act { click_ci_cd_pipelines }
        Page::Project::Pipeline::Index.act { go_to_latest_pipeline }

        Page::Project::Pipeline::Show.act do
          go_to_first_job

          wait do
            !has_content?('running')
          end
        end

        Page::Project::Job::Show.perform do |job|
          expect(job.output).to include(sha1sum)
        end
      end
    end
  end
end
