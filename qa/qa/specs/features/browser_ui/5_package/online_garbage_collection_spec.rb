# frozen_string_literal: true

module QA
  RSpec.describe 'Package' do
    describe 'Container Registry Online Garbage Collection', :registry_gc, only: { subdomain: %i[pre] } do
      let(:group) { Resource::Group.fabricate_via_api! }

      let(:imported_project) do
        Resource::ProjectImportedFromURL.fabricate_via_browser_ui! do |project|
          project.name = 'container-registry'
          project.group = group
          project.gitlab_repository_path = 'https://gitlab.com/gitlab-org/container-registry.git'
        end
      end

      let!(:gitlab_ci_yaml) do
        <<~YAML
          variables:
            GOPATH: $CI_PROJECT_DIR/.go
            BUILD_CACHE: $CI_PROJECT_DIR/.online-gc-tester
            STAGE_ONE_VALIDATION_DELAY: "6m"
            STAGE_TWO_VALIDATION_DELAY: "12m"
            STAGE_THREE_VALIDATION_DELAY: "6m"
            STAGE_FOUR_VALIDATION_DELAY: "12m"
            STAGE_FIVE_VALIDATION_DELAY: "12m"
                   
          stages:
            - generate
            - build
            - test
          
          .base: &base
            image: docker:19
            services:
              - docker:19-dind
            variables:
              DOCKER_HOST: tcp://docker:2376
              DOCKER_TLS_CERTDIR: "/certs"
              DOCKER_TLS_VERIFY: 1
              DOCKER_CERT_PATH: "$DOCKER_TLS_CERTDIR/client"
            before_script:
              - until docker info; do sleep 1; done 
              - mkdir -p $GOPATH
              - mkdir -p $BUILD_CACHE
              - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
          
          test:
            stage: generate
            extends: .base
            script:
              - apk add go make git
              - make binaries
              - ./bin/online-gc-tester generate --base-dir=$BUILD_CACHE
              - ./bin/online-gc-tester build --base-dir=$BUILD_CACHE
              - ./bin/online-gc-tester push --base-dir=$BUILD_CACHE
              - ./bin/online-gc-tester pull --base-dir=$BUILD_CACHE
              - ./bin/online-gc-tester test --base-dir=$BUILD_CACHE --stage=1 --delay=$STAGE_ONE_VALIDATION_DELAY
              - ./bin/online-gc-tester test --base-dir=$BUILD_CACHE --stage=2 --delay=$STAGE_TWO_VALIDATION_DELAY
              - ./bin/online-gc-tester test --base-dir=$BUILD_CACHE --stage=3 --delay=$STAGE_THREE_VALIDATION_DELAY
              - ./bin/online-gc-tester test --base-dir=$BUILD_CACHE --stage=4 --delay=$STAGE_FOUR_VALIDATION_DELAY
              - ./bin/online-gc-tester test --base-dir=$BUILD_CACHE --stage=5 --delay=$STAGE_FIVE_VALIDATION_DELAY
            timeout: 1h 30m
        YAML
      end

      before do
        Flow::Login.sign_in

        imported_project

        Page::Project::Menu.perform(&:go_to_repository_settings)

        Page::Project::Settings::Repository.perform do |setting|
          setting.expand_default_branch
        end

        Page::Project::Settings::DefaultBranch.perform do |setting|
          setting.set_default_branch('online-gc-test-builder-poc')
          setting.click_save_changes_button
        end

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = imported_project
          commit.branch = 'online-gc-test-builder-poc'
          commit.commit_message = 'Update .gitlab-ci.yml'
          commit.update_files([{
                              file_path: '.gitlab-ci.yml',
                              content: gitlab_ci_yaml
                            }])
        end
      end

      it 'runs the online garbage collector tool', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1854' do
        imported_project.visit!

        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('test')
        end

        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 3900)
        end
      end
    end
  end
end
