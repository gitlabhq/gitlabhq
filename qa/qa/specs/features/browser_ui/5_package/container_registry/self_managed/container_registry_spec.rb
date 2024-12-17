# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :skip_live_env, product_group: :container_registry do
    describe 'Self-managed Container Registry' do
      include Support::Helpers::MaskToken

      let(:project) { create(:project, :private, name: 'project-with-registry', template_name: 'express') }
      let(:project_deploy_token) do
        create(:project_deploy_token,
          name: 'registry-deploy-token',
          project: project,
          scopes: %w[
            read_repository
            read_package_registry
            write_package_registry
            read_registry
            write_registry
          ])
      end

      let!(:runner) do
        create(:project_runner,
          name: "qa-runner-#{SecureRandom.hex(6)}",
          tags: ["runner-for-#{project.name}"],
          executor: :docker,
          project: project)
      end

      let(:personal_access_token) { Runtime::User::Store.default_api_client.personal_access_token }
      let(:gitlab_host_without_port) { Support::GitlabAddress.host_with_port(with_default_port: false) }
      let(:omnibus_registry_port) { 5050 }
      let(:cng_registry_port) { 5000 }
      let(:registry_port) do
        is_nip_io = gitlab_host_without_port.match?(/gitlab\.\d+\.\d+\.\d+\.\d+\.nip\.io/)
        is_nip_io ? cng_registry_port : omnibus_registry_port
      end

      let(:repository_path) { "#{gitlab_host_without_port}:#{registry_port}/#{project.full_path}" }

      before do
        Flow::Login.sign_in
        project.visit!
      end

      context "when tls is disabled" do
        where do
          {
            'using docker:24.0.1 and a personal access token' => {
              authentication_token_type: :personal_access_token,
              token_name: 'Personal access token',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/412817'
            },
            'using docker:24.0.1 and a project deploy token' => {
              authentication_token_type: :project_deploy_token,
              token_name: 'Deploy Token',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/412818'
            },
            'using docker:24.0.1 and a ci job token' => {
              authentication_token_type: :ci_job_token,
              token_name: 'Job Token',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/412819'
            }
          }
        end

        with_them do
          let(:auth_token) do
            case authentication_token_type
            when :personal_access_token
              use_ci_variable(name: 'PERSONAL_ACCESS_TOKEN', value: personal_access_token, project: project)
            when :project_deploy_token
              use_ci_variable(name: 'PROJECT_DEPLOY_TOKEN', value: project_deploy_token.token, project: project)
            when :ci_job_token
              '$CI_JOB_TOKEN'
            end
          end

          let(:auth_user) do
            case authentication_token_type
            when :personal_access_token
              "$CI_REGISTRY_USER"
            when :project_deploy_token
              "\"#{project_deploy_token.username}\""
            when :ci_job_token
              'gitlab-ci-token'
            end
          end

          it "pushes image and deletes tag", :registry, testcase: params[:testcase] do
            create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
              {
                action: 'create',
                file_path: '.gitlab-ci.yml',
                content: <<~YAML
                  build:
                    image: "docker:24.0.1"
                    stage: build
                    services:
                    - name: "docker:24.0.1-dind"
                      command: ["--insecure-registry=#{gitlab_host_without_port}:#{registry_port}"]
                    variables:
                      DOCKER_TLS_CERTDIR: ""
                    before_script:
                      - |
                        echo "Waiting for docker to start..."
                        for i in $(seq 1 30); do
                          docker info && break
                          sleep 1s
                        done
                    script:
                      - docker login -u #{auth_user} -p #{auth_token} #{gitlab_host_without_port}:#{registry_port}
                      - docker build -t #{repository_path} .
                      - docker push #{repository_path}
                    tags:
                      - "runner-for-#{project.name}"
                YAML
              }
            ])

            Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
            project.visit_job('build')
            Page::Project::Job::Show.perform do |job|
              expect(job).to be_successful(timeout: 800)
            end

            Page::Project::Menu.perform(&:go_to_container_registry)
            Page::Project::Registry::Show.perform do |registry|
              expect(registry).to have_registry_repository(project.name)

              registry.click_on_image(project.name)
              expect(registry).to have_tag('latest')
            end
          end
        end
      end

      context 'when tls is enabled' do
        it(
          'pushes image and deletes tag',
          :registry_tls,
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347591'
        ) do
          create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
            {
              action: 'create',
              file_path: '.gitlab-ci.yml',
              content: <<~YAML
                  build:
                    image: "docker:24.0.1"
                    stage: build
                    services:
                      - name: "docker:24.0.1-dind"
                        command:
                          - /bin/sh
                          - -c
                          - |
                            apk add --no-cache openssl
                            true | openssl s_client -showcerts -connect gitlab.test:5050 > /usr/local/share/ca-certificates/gitlab.test.crt
                            update-ca-certificates
                            dockerd-entrypoint.sh || exit
                    variables:
                      IMAGE_TAG: "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG"
                    script:
                      - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD gitlab.test:5050
                      - docker build -t $IMAGE_TAG .
                      - docker push $IMAGE_TAG
                    tags:
                      - "runner-for-#{project.name}"
              YAML
            }
          ])

          Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
          project.visit_job('build')
          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 200)
          end

          Flow::Pipeline.wait_for_latest_pipeline_to_have_status(project: project, status: 'success')
          Page::Project::Menu.perform(&:go_to_container_registry)
          Page::Project::Registry::Show.perform do |registry|
            expect(registry).to have_registry_repository(project.name)

            registry.click_on_image(project.name)

            expect(registry).to have_tag('master')

            registry.click_delete

            expect { registry.has_no_tag?('master') }
              .to eventually_be_truthy.within(max_duration: 60, reload_page: page)
          end
        end
      end
    end
  end
end
