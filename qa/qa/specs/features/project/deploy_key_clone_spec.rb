require 'digest/sha1'

module QA
  feature 'cloning code using a deploy key', :core, :docker do
    def login
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }
    end

    before(:all) do
      login

      @runner_name = "qa-runner-#{Time.now.to_i}"

      @project = Factory::Resource::Project.fabricate! do |resource|
        resource.name = 'deploy-key-clone-project'
      end

      @repository_uri = @project.repository_ssh_uri

      Factory::Resource::Runner.fabricate! do |resource|
        resource.project = @project
        resource.name = @runner_name
        resource.tags = %w[qa docker]
        resource.image = 'gitlab/gitlab-runner:ubuntu'
      end

      Page::Menu::Main.act { sign_out }
    end

    after(:all) do
      Service::Runner.new(@runner_name).remove!
    end

    keys = [
      Runtime::Key::RSA.new(8192),
      Runtime::Key::ECDSA.new(521),
      Runtime::Key::ED25519.new
    ]

    keys.each do |key|
      scenario "user sets up a deploy key with #{key.name}(#{key.bits}) to clone code using pipelines" do
        login

        Factory::Resource::DeployKey.fabricate! do |resource|
          resource.project = @project
          resource.title = "deploy key #{key.name}(#{key.bits})"
          resource.key = key.public_key
        end

        deploy_key_name = "DEPLOY_KEY_#{key.name}_#{key.bits}"

        Factory::Resource::SecretVariable.fabricate! do |resource|
          resource.project = @project
          resource.key = deploy_key_name
          resource.value = key.private_key
        end

        gitlab_ci = <<~YAML
          cat-config:
            script:
              - mkdir -p ~/.ssh
              - ssh-keyscan -p #{@repository_uri.port} #{@repository_uri.host} >> ~/.ssh/known_hosts
              - eval $(ssh-agent -s)
              - ssh-add -D
              - echo "$#{deploy_key_name}" | ssh-add -
              - git clone #{@repository_uri.git_uri}
              - sha1sum #{@project.name}/.gitlab-ci.yml
            tags:
              - qa
              - docker
        YAML

        Factory::Repository::Push.fabricate! do |resource|
          resource.project = @project
          resource.file_name = '.gitlab-ci.yml'
          resource.commit_message = 'Add .gitlab-ci.yml'
          resource.file_content = gitlab_ci
          resource.branch_name = deploy_key_name
          resource.new_branch = true
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
