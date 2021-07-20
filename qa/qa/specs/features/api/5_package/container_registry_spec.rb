# frozen_string_literal: true

require 'airborne'

module QA
  RSpec.describe 'Package', only: { subdomain: %i[staging pre] } do
    include Support::Api

    describe 'Container Registry' do
      let(:api_client) { Runtime::API::Client.new(:gitlab) }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-registry-api'
          project.template_name = 'express'
          project.api_client = api_client
        end
      end

      let(:registry) do
        Resource::RegistryRepository.init do |repository|
          repository.name = project.path_with_namespace
          repository.project = project
          repository.tag_name = 'master'
        end
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
            variables:
              MEDIA_TYPE: 'application/vnd.docker.distribution.manifest.v2+json'
            before_script:
              - token=$(curl -u "$CI_REGISTRY_USER:$CI_REGISTRY_PASSWORD" "https://$CI_SERVER_HOST/jwt/auth?service=container_registry&scope=repository:$CI_PROJECT_PATH:pull,push,delete" | jq -r '.token')
              - echo $token
            script:
              - 'digest=$(curl -L -H "Authorization: Bearer $token" -H "Accept: $MEDIA_TYPE" "https://$CI_REGISTRY/v2/$CI_PROJECT_PATH/manifests/master" | jq -r ".layers[0].digest")'
              - 'curl -L -X DELETE -H "Authorization: Bearer $token" -H "Accept: $MEDIA_TYPE" "https://$CI_REGISTRY/v2/$CI_PROJECT_PATH/blobs/$digest"'
              - 'curl -L --head -H "Authorization: Bearer $token" -H "Accept: $MEDIA_TYPE" "https://$CI_REGISTRY/v2/$CI_PROJECT_PATH/blobs/$digest"'
              - 'digest=$(curl -L -H "Authorization: Bearer $token" -H "Accept: $MEDIA_TYPE" "https://$CI_REGISTRY/v2/$CI_PROJECT_PATH/manifests/master" | jq -r ".config.digest")'
              - 'curl -L -X DELETE -H "Authorization: Bearer $token" -H "Accept: $MEDIA_TYPE" "https://$CI_REGISTRY/v2/$CI_PROJECT_PATH/manifests/$digest"'
              - 'curl -L --head -H "Authorization: Bearer $token" -H "Accept: $MEDIA_TYPE" "https://$CI_REGISTRY/v2/$CI_PROJECT_PATH/manifests/$digest"'
        YAML
      end

      after do
        registry&.remove_via_api!
      end

      it 'pushes, pulls image to the registry and deletes image blob, manifest and tag', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1738' do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.api_client = api_client
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.project = project
          commit.add_files([{
                                file_path: '.gitlab-ci.yml',
                                content: gitlab_ci_yaml
                            }])
        end

        Support::Waiter.wait_until(max_duration: 10) { pipeline_is_triggered? }

        Support::Retrier.retry_until(max_duration: 300, sleep_interval: 5) do
          latest_pipeline_succeed?
        end

        expect(job_log).to have_content '404 Not Found'

        expect(registry).to have_tag('master')

        registry.delete_tag

        expect(registry).not_to have_tag('master')
      end

      private

      def pipeline_is_triggered?
        !project.pipelines.empty?
      end

      def latest_pipeline_succeed?
        latest_pipeline = project.pipelines.first
        latest_pipeline[:status] == 'success'
      end

      def job_log
        pipeline = project.pipelines.first
        pipeline_id = pipeline[:id]

        jobs = get Runtime::API::Request.new(api_client, "/projects/#{project.id}/pipelines/#{pipeline_id}/jobs").url
        test_job = parse_body(jobs).first
        test_job_id = test_job[:id]

        log = get Runtime::API::Request.new(api_client, "/projects/#{project.id}/jobs/#{test_job_id}/trace").url
        QA::Runtime::Logger.debug(" \n\n ------- Test job log: ------- \n\n #{log} \n -------")

        log
      end
    end
  end
end
