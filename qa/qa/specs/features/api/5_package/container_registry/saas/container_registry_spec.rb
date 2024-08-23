# frozen_string_literal: true

module QA
  RSpec.describe 'Package', only: { subdomain: %i[staging staging-canary pre] },
    product_group: :container_registry do
    include Support::API
    include Support::Helpers::MaskToken
    include Support::Data::Image

    describe 'SaaS Container Registry API' do
      let(:api_client) { Runtime::API::Client.new(:gitlab) }
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }

      let(:project) do
        create(:project, name: 'project-with-registry-api', template_name: 'express', api_client: api_client)
      end

      let!(:runner) do
        create(:project_runner, project: project, name: executor, tags: [executor], executor: :docker)
      end

      let!(:project_access_token) { create(:project_access_token, project: project) }

      let(:masked_token) do
        use_ci_variable(name: 'PAT', value: project_access_token.token, project: project)
      end

      let(:gitlab_ci_yaml) do
        <<~YAML
        stages:
        - build
        - test

        build:
          image: docker:24.0.1
          stage: build
          services:
            - docker:24.0.1-dind
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
          image: #{ci_test_image}
          stage: test
          script:
            - 'id=$(curl --header "PRIVATE-TOKEN: #{masked_token}" "https://${CI_SERVER_HOST}/api/v4/projects/#{project.id}/registry/repositories" | tac | jq ".[0].id")'
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
        runner.remove_via_api!
      end

      it 'pushes, pulls image to the registry and deletes tag',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348001' do
        Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2, message: "Commit push") do
          create(:commit, api_client: api_client, commit_message: 'Add .gitlab-ci.yml', project: project, actions: [
            { action: 'create', file_path: '.gitlab-ci.yml', content: gitlab_ci_yaml }
          ])
        end

        Support::Retrier.retry_until(
          max_duration: 30,
          sleep_interval: 1,
          message: "Waiting for pipeline to start"
        ) do
          pipeline_is_triggered?
        end
        Support::Retrier.retry_until(
          max_duration: 300,
          sleep_interval: 5,
          message: "Waiting for pipeline to succeed"
        ) do
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
