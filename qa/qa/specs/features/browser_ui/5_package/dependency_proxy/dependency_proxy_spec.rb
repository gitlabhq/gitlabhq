# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :registry, :skip_live_env, product_group: :container_registry do
    describe 'Dependency Proxy' do
      using RSpec::Parameterized::TableSyntax
      include Support::Helpers::MaskToken

      let(:project) { create(:project, :private, name: 'dependency-proxy-project') }
      let!(:runner) do
        create(:project_runner,
          name: "qa-runner-#{SecureRandom.hex(6)}",
          tags: ["runner-for-#{project.name}"],
          executor: :docker,
          project: project)
      end

      let(:group_deploy_token) do
        create(:group_deploy_token,
          name: 'dp-group-deploy-token',
          group: project.group,
          scopes: %w[read_registry write_registry])
      end

      let(:personal_access_token) { Runtime::User::Store.default_api_client.personal_access_token }
      let(:gitlab_host_with_port) { Support::GitlabAddress.host_with_port }
      let(:dependency_proxy_url) { "#{gitlab_host_with_port}/#{project.group.full_path}/dependency_proxy/containers" }
      let(:image_sha) { 'alpine@sha256:c3d45491770c51da4ef58318e3714da686bc7165338b7ab5ac758e75c7455efb' }

      before do
        Flow::Login.sign_in
        project.group.visit!
      end

      after do
        runner.remove_via_api!
      end

      where do
        {
          'using docker:24.0.1 and a personal access token' => {
            docker_client_version: 'docker:24.0.1',
            authentication_token_type: :personal_access_token,
            token_name: 'Personal access token',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/412820'
          },
          'using docker:24.0.1 and a group deploy token' => {
            docker_client_version: 'docker:24.0.1',
            authentication_token_type: :group_deploy_token,
            token_name: 'Deploy Token',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/412821'
          },
          'using docker:24.0.1 and a ci job token' => {
            docker_client_version: 'docker:24.0.1',
            authentication_token_type: :ci_job_token,
            token_name: 'Job Token',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/412822'
          }
        }
      end

      with_them do
        let(:auth_token) do
          case authentication_token_type
          when :personal_access_token
            use_ci_variable(name: 'PERSONAL_ACCESS_TOKEN', value: personal_access_token, project: project)
          when :group_deploy_token
            use_group_ci_variable(
              name: "GROUP_DEPLOY_TOKEN_#{group_deploy_token.id}",
              value: group_deploy_token.token,
              group: project.group
            )
          when :ci_job_token
            '$CI_JOB_TOKEN'
          end
        end

        let(:auth_user) do
          case authentication_token_type
          when :personal_access_token
            "$CI_REGISTRY_USER"
          when :group_deploy_token
            "\"#{group_deploy_token.username}\""
          when :ci_job_token
            'gitlab-ci-token'
          end
        end

        it "pulls an image using the dependency proxy", testcase: params[:testcase] do
          Page::Group::Menu.perform(&:go_to_package_settings)
          Page::Group::Settings::PackageRegistries.perform do |index|
            expect(index).to have_dependency_proxy_enabled
          end

          create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
            {
              action: 'create',
              file_path: '.gitlab-ci.yml',
              content: <<~YAML
                  dependency-proxy-pull-test:
                    image: "#{docker_client_version}"
                    services:
                      - name: "#{docker_client_version}-dind"
                        command: ["--insecure-registry=#{gitlab_host_with_port}"]
                    variables:
                      DOCKER_TLS_CERTDIR: ""
                    before_script:
                      - |
                        echo "Waiting for docker to start..."
                        for i in $(seq 1 30); do
                          docker info && break
                          sleep 1s
                        done
                      - apk add curl jq grep
                      - docker login -u #{auth_user} -p #{auth_token} #{gitlab_host_with_port}
                    script:
                      - docker pull #{dependency_proxy_url}/#{image_sha}
                      - TOKEN=$(curl "https://auth.docker.io/token?service=registry.docker.io&scope=repository:ratelimitpreview/test:pull" | jq --raw-output .token)
                      - 'curl --head --header "Authorization: Bearer $TOKEN" "https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest" 2>&1'
                      - docker pull #{dependency_proxy_url}/#{image_sha}
                      - 'curl --head --header "Authorization: Bearer $TOKEN" "https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest" 2>&1'
                    tags:
                      - "runner-for-#{project.name}"
              YAML
            }
          ])

          project.visit!
          Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
          project.visit_job('dependency-proxy-pull-test')
          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end

          project.group.visit!
          Page::Group::Menu.perform(&:go_to_dependency_proxy)
          Page::Group::DependencyProxy.perform do |index|
            expect(index).to have_blob_count(/Contains [1-9]\d* blobs of images/)
          end
        end
      end
    end
  end
end
