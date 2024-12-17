# frozen_string_literal: true

require 'digest/sha1'

module QA
  RSpec.describe 'Release', :runner, product_group: :environments do
    describe 'Git clone using a deploy key' do
      let(:runner_name) { "qa-runner-#{SecureRandom.hex(4)}" }
      let(:repository_location) { project.repository_ssh_location }
      let(:project) { create(:project, name: 'deploy-key-clone-project') }
      let!(:runner) { create(:project_runner, project: project, name: runner_name, tags: [runner_name]) }

      before do
        Flow::Login.sign_in
      end

      after do
        runner.remove_via_api!
      end

      keys = [
        ['https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348022', Runtime::Key::RSA, 8192, true],
        ['https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348021', Runtime::Key::ECDSA, 521, true],
        ['https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348020', Runtime::Key::ED25519, 256, false]
      ]

      supported_keys =
        if QA::Support::FIPS.enabled?
          keys.select { |(_, _, _, allowed_in_fips)| allowed_in_fips }
        else
          keys
        end

      supported_keys.each do |(testcase, key_class, bits, _)|
        it "user sets up a deploy key with #{key_class}(#{bits}) to clone code using pipelines", testcase: testcase do
          key = key_class.new(*bits)

          Resource::DeployKey.fabricate_via_browser_ui! do |resource|
            resource.project = project
            resource.title = "deploy key #{key.name}(#{key.bits})"
            resource.key = key.public_key
          end

          deploy_key_name = "DEPLOY_KEY_#{key.name}_#{key.bits}"

          make_ci_variable(deploy_key_name, key)

          gitlab_ci = <<~YAML
            cat-config:
              script:
                - which ssh-agent || ( apk --update add openssh-client )
                - mkdir -p ~/.ssh
                - ssh-keyscan -p #{repository_location.port} #{repository_location.host} >> ~/.ssh/known_hosts
                - eval $(ssh-agent -s)
                - ssh-add -D
                - echo "$#{deploy_key_name}" | ssh-add -
                - git clone #{repository_location.git_uri}
                - cd #{project.name}
                - git checkout #{deploy_key_name}
                - sha1sum .gitlab-ci.yml
              tags: [#{runner_name}]
          YAML

          Resource::Repository::ProjectPush.fabricate! do |resource|
            resource.project = project
            resource.file_name = '.gitlab-ci.yml'
            resource.commit_message = 'Add .gitlab-ci.yml'
            resource.file_content = gitlab_ci
            resource.branch_name = deploy_key_name
            resource.new_branch = true
          end

          sha1sum = Digest::SHA1.hexdigest(gitlab_ci)

          Flow::Pipeline.visit_latest_pipeline
          Page::Project::Pipeline::Show.perform(&:click_on_first_job)

          Page::Project::Job::Show.perform do |job|
            aggregate_failures 'job succeeds and has correct sha1sum' do
              expect(job).to be_successful
              expect(job.output).to include(sha1sum)
            end
          end
        end

        private

        def make_ci_variable(key_name, key)
          create(:ci_variable, project: project, key: key_name, value: key.private_key)
        end
      end
    end
  end
end
