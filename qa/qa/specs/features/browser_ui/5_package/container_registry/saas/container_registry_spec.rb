# frozen_string_literal: true

module QA
  RSpec.describe 'Package' do
    describe 'SaaS Container Registry', only: { subdomain: %i[staging staging-canary pre] },
      product_group: :container_registry do
      let(:project) { create(:project, name: 'project-with-registry', template_name: 'express') }
      let(:gitlab_ci_yaml) do
        <<~YAML
          stages:
          - test
          - build

          test:
            image: registry.gitlab.com/gitlab-ci-utils/curl-jq:latest
            stage: test
            script:
              - 'status_code=$(curl --header "Authorization: Bearer $CI_JOB_TOKEN" "https://${CI_SERVER_HOST}/gitlab/v1")'
              - |
                if [ "$status_code" -eq 404 ]; then
                  echo "The registry implements this API specification, but it is unavailable because the metadata database is disabled."
                  exit 1
                fi
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
              - |
                echo "Waiting for docker to start..."
                for i in $(seq 1 30); do
                  docker info && break
                  sleep 1s
                done
            script:
              - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
              - docker build -t $IMAGE_TAG .
              - docker push $IMAGE_TAG
        YAML
      end

      before do
        create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
          { action: 'create', file_path: '.gitlab-ci.yml', content: gitlab_ci_yaml }
        ])

        Flow::Login.sign_in
        project.visit!
      end

      it 'pushes project image to the container registry and deletes tag',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/412806' do
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
        project.visit_job('test')
        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 200)
        end

        project.visit_job('build')
        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 500)
        end

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
