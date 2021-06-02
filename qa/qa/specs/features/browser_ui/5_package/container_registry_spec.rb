# frozen_string_literal: true

module QA
  RSpec.describe 'Package' do
    describe 'Container Registry', :reliable, only: { subdomain: %i[staging pre] } do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-registry'
          project.template_name = 'express'
        end
      end

      let(:registry_repository) do
        Resource::RegistryRepository.fabricate! do |repository|
          repository.name = "#{project.path_with_namespace}"
          repository.project = project
        end
      end

      let!(:gitlab_ci_yaml) do
        <<~YAML
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
              - |
                echo "Waiting for docker to start..."
                for i in $(seq 1 30)
                do
                    docker info && break
                    sleep 1s
                done       
            script:
              - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
              - docker build -t $IMAGE_TAG .
              - docker push $IMAGE_TAG
        YAML
      end

      after do
        registry_repository&.remove_via_api!
      end

      it 'pushes project image to the container registry and deletes tag', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1699' do
        Flow::Login.sign_in
        project.visit!

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files([{
                              file_path: '.gitlab-ci.yml',
                              content: gitlab_ci_yaml
                            }])
        end

        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('build')
        end

        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 800)
        end

        Page::Project::Menu.perform(&:go_to_container_registry)

        Page::Project::Registry::Show.perform do |registry|
          expect(registry).to have_registry_repository(registry_repository.name)

          registry.click_on_image(registry_repository.name)
          expect(registry).to have_tag('master')

          registry.click_delete
          expect(registry).not_to have_tag('master')
        end
      end
    end
  end
end
