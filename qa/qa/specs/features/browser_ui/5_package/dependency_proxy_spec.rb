# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :registry do
    describe 'Dependency Proxy' do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'dependency-proxy-project'
          project.visibility = :private
        end
      end

      let!(:runner) do
        Resource::Runner.fabricate! do |runner|
          runner.name = "qa-runner-#{Time.now.to_i}"
          runner.tags = ["runner-for-#{project.name}"]
          runner.executor = :docker
          runner.project = project
        end
      end

      let(:uri) { URI.parse(Runtime::Scenario.gitlab_address) }
      let(:gitlab_host_with_port) { "#{uri.host}:#{uri.port}" }
      let(:dependency_proxy_url) { "#{gitlab_host_with_port}/#{project.group.full_path}/dependency_proxy/containers" }

      before do
        Flow::Login.sign_in

        project.group.visit!

        Page::Group::Menu.perform(&:go_to_dependency_proxy)

        Page::Group::DependencyProxy.perform do |index|
          expect(index).to have_dependency_proxy_enabled
        end
      end

      after do
        runner.remove_via_api!
      end

      where(:docker_client_version) do
        %w[docker:19.03.12 docker:20.10]
      end

      with_them do
        it "pulls an image using the dependency proxy", testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1862' do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = project
            commit.commit_message = 'Add .gitlab-ci.yml'
            commit.add_files([{
                                file_path: '.gitlab-ci.yml',
                                content:
                                    <<~YAML
                                      dependency-proxy-pull-test:
                                        image: "#{docker_client_version}"
                                        services:
                                        - name: "#{docker_client_version}-dind"
                                          command:
                                          - /bin/sh
                                          - -c
                                          - |
                                            apk add --no-cache openssl
                                            true | openssl s_client -showcerts -connect gitlab.test:5050 > /usr/local/share/ca-certificates/gitlab.test.crt
                                            update-ca-certificates
                                            dockerd-entrypoint.sh || exit     
                                        before_script:
                                          - apk add curl jq grep
                                          - docker login -u "$CI_DEPENDENCY_PROXY_USER" -p "$CI_DEPENDENCY_PROXY_PASSWORD" "$CI_DEPENDENCY_PROXY_SERVER"
                                        script:
                                          - docker pull #{dependency_proxy_url}/alpine:latest
                                          - TOKEN=$(curl "https://auth.docker.io/token?service=registry.docker.io&scope=repository:ratelimitpreview/test:pull" | jq --raw-output .token)
                                          - 'curl --head --header "Authorization: Bearer $TOKEN" "https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest" 2>&1'
                                          - docker pull #{dependency_proxy_url}/alpine:latest
                                          - 'curl --head --header "Authorization: Bearer $TOKEN" "https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest" 2>&1'
                                        tags:
                                        - "runner-for-#{project.name}"
                                    YAML
                            }])
          end

          project.visit!
          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('dependency-proxy-pull-test')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end

          project.group.visit!

          Page::Group::Menu.perform(&:go_to_dependency_proxy)

          Page::Group::DependencyProxy.perform do |index|
            expect(index).to have_blob_count("Contains 2 blobs of images")
          end
        end
      end
    end
  end
end
