# frozen_string_literal: true

require 'airborne'

module QA
  RSpec.describe 'Package', :reliable, only: { subdomain: %i[staging staging-canary pre] }, product_group: :container_registry do
    include Support::API
    include Support::Helpers::MaskToken

    describe 'Container Registry' do
      let(:api_client) { Runtime::API::Client.new(:gitlab) }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-registry-api'
          project.template_name = 'express'
          project.api_client = api_client
        end
      end

      let!(:project_access_token) do
        QA::Resource::ProjectAccessToken.fabricate_via_api! do |pat|
          pat.project = project
        end
      end

      let(:registry) do
        Resource::RegistryRepository.init do |repository|
          repository.name = project.path_with_namespace
          repository.project = project
          repository.tag_name = 'master'
        end
      end

      let(:masked_token) do
        use_ci_variable(name: 'PAT', value: project_access_token.token, project: project)
      end

      let(:gitlab_ci_yaml) do
        <<~YAML
        stages:
        - build
        - test

        build:
          image: docker:19.03.12
          stage: build
          services:
            - docker:19.03.12-dind
          variables:
            IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
            DOCKER_HOST: tcp://docker:2376
            DOCKER_TLS_CERTDIR: "/certs"
            DOCKER_TLS_VERIFY: 1
            DOCKER_CERT_PATH: "$DOCKER_TLS_CERTDIR/client"
          before_script:
            - until docker info; do sleep 1; done
          script:
            - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
            - docker build -t $IMAGE_TAG .
            - docker push $IMAGE_TAG
            - docker pull $IMAGE_TAG

        test:
          image: dwdraju/alpine-curl-jq:latest
          stage: test
          script:
            - 'id=$(curl --header "PRIVATE-TOKEN: #{masked_token}" "https://${CI_SERVER_HOST}/api/v4/projects/#{project.id}/registry/repositories" | jq ".[0].id")'
            - echo $id
            - 'tag_count=$(curl --header "PRIVATE-TOKEN: #{masked_token}" "https://${CI_SERVER_HOST}/api/v4/projects/#{project.id}/registry/repositories/$id/tags" | jq ". | length")'
            - if [ $tag_count -ne 1 ]; then exit 1; fi;
            - 'status_code=$(curl --request DELETE --head --output /dev/null --write-out "%{http_code}\n" --header "PRIVATE-TOKEN: #{masked_token}" "https://${CI_SERVER_HOST}/api/v4/projects/#{project.id}/registry/repositories/$id/tags/master")'
            - if [ $status_code -ne 200 ]; then exit 1; fi;
            - 'status_code=$(curl --head --output /dev/null --write-out "%{http_code}\n" --header "PRIVATE-TOKEN: #{masked_token}" "https://${CI_SERVER_HOST}/api/v4/projects/#{project.id}/registry/repositories/$id/tags/master")'
            - if [ $status_code -ne 404 ]; then exit 1; fi;
        YAML
      end

      after do
        registry&.remove_via_api!
      end

      it 'pushes, pulls image to the registry and deletes tag', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348001' do
        Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.api_client = api_client
            commit.commit_message = 'Add .gitlab-ci.yml'
            commit.project = project
            commit.add_files([{
                                  file_path: '.gitlab-ci.yml',
                                  content: gitlab_ci_yaml
                              }])
          end
        end

        Support::Waiter.wait_until(max_duration: 10) { pipeline_is_triggered? }

        Support::Retrier.retry_until(max_duration: 300, sleep_interval: 5) do
          latest_pipeline_succeed?
        end
      end

      private

      def pipeline_is_triggered?
        !project.pipelines.empty?
      end

      def latest_pipeline_succeed?
        latest_pipeline = project.pipelines.first
        latest_pipeline[:status] == 'success'
      end
    end
  end
end
