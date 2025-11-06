# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :object_storage, :external_api_calls, feature_category: :package_registry,
    quarantine: {
      only: { condition: -> { QA::Support::FIPS.enabled? } },
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/417600',
      type: :investigating
    } do
    describe 'Maven Repository with Gradle' do
      using RSpec::Parameterized::TableSyntax
      include Runtime::Fixtures
      include Support::Helpers::MaskToken

      let(:group_id) { 'com.gitlab.qa' }
      let(:artifact_id) { "maven_gradle-#{SecureRandom.hex(8)}" }
      let(:package_name) { "#{group_id}/#{artifact_id}".tr('.', '/') }
      let(:package_version) { '1.3.7' }
      let(:package_type) { 'maven_gradle' }
      let(:project) { create(:project, name: "#{package_type}_project") }
      let(:gitlab_address_with_port) do
        Support::GitlabAddress.address_with_port
      end

      before do
        Flow::Login.sign_in_unless_signed_in
      end

      context 'with ci deploy token' do
        let(:maven_header_name) { 'Job-Token' }
        let(:token) do
          project_inbound_job_token_disabled
          '${CI_JOB_TOKEN}'
        end

        let(:project_inbound_job_token_disabled) do
          Resource::CICDSettings.fabricate_via_api! do |settings|
            settings.project_path = project.full_path
            settings.inbound_job_token_scope_enabled = false
          end
        end

        let!(:runner) do
          create(:project_runner,
            name: "qa-runner-#{SecureRandom.hex(6)}",
            tags: ["runner-for-#{project.name}"],
            executor: :docker,
            project: project)
        end

        it 'pushes and pulls a maven package via gradle, using a pipeline',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/562424' do
          gradle_publish_install_yaml = ERB.new(read_fixture('package_managers/maven/gradle',
            'gradle_upload_install_package.yaml.erb')).result(binding)
          build_gradle = ERB.new(read_fixture('package_managers/maven/gradle', 'build.gradle.erb')).result(binding)

          create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
            { action: 'create', file_path: '.gitlab-ci.yml', content: gradle_publish_install_yaml },
            { action: 'create', file_path: 'build.gradle', content: build_gradle }
          ])

          project.visit!
          Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)

          project.visit_job('publish')
          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end

          project.visit_job('install')
          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end

          Page::Project::Menu.perform(&:go_to_package_registry)
          Page::Project::Packages::Index.perform do |index|
            expect(index).to have_package(package_name)

            index.click_package(package_name)
          end

          Page::Project::Packages::Show.perform do |show|
            expect(show).to have_package_info(name: nil, version: package_version)
          end
        end
      end

      context 'with other token types' do
        let(:published_java_source) do
          {
            file_path: 'src/main/java/com/gitlab/qa/HelloWorld.java',
            content: <<~JAVA
              package com.gitlab.qa;

              public class HelloWorld {
                  public static String getMessage() {
                      return "Hello from published package!";
                  }
              }
            JAVA
          }
        end

        let(:publish_gradle) do
          {
            file_path: 'publish.gradle',
            content: <<~GRADLE
            plugins {
              id 'java'
              id 'maven-publish'
            }

            group '#{group_id}'
            version '#{package_version}'

            repositories {
              maven {
                url "#{gitlab_address_with_port}/api/v4/projects/#{project.id}/packages/maven"
                credentials(HttpHeaderCredentials) {
                  name = '#{maven_header_name}'
                  value = "#{token}"
                }
                allowInsecureProtocol = true
                authentication {
                  header(HttpHeaderAuthentication)
                }
              }
            }

            publishing {
              publications {
                library(MavenPublication) {
                  from components.java
                }
              }
              repositories {
                maven {
                  url "#{gitlab_address_with_port}/api/v4/projects/#{project.id}/packages/maven"
                  credentials(HttpHeaderCredentials) {
                    name = '#{maven_header_name}'
                    value = "#{token}"
                  }
                  allowInsecureProtocol = true
                  authentication {
                    header(HttpHeaderAuthentication)
                  }
                }
              }
            }
            GRADLE
          }
        end

        let(:consumer_java_source) do
          {
            file_path: 'src/main/java/TestApp.java',
            content: <<~JAVA
              import com.gitlab.qa.HelloWorld;

              public class TestApp {
                  public static void main(String[] args) {
                      System.out.println(HelloWorld.getMessage());
                  }
              }
            JAVA
          }
        end

        let(:install_gradle) do
          {
            file_path: 'install.gradle',
            content: <<~GRADLE
              plugins {
                id 'java'
              }

              group 'install-group'
              version '3.3.7'

              repositories {
                maven {
                  url "#{gitlab_address_with_port}/api/v4/projects/#{project.id}/packages/maven"
                  credentials(HttpHeaderCredentials) {
                    name = '#{maven_header_name}'
                    value = "#{token}"
                  }
                  allowInsecureProtocol = true
                  authentication {
                    header(HttpHeaderAuthentication)
                  }
                }
              }

              dependencies {
                implementation '#{group_id}:#{artifact_id}:#{package_version}'
              }
            GRADLE
          }
        end

        before do
          with_fixtures([published_java_source, publish_gradle, consumer_java_source, install_gradle]) do |dir|
            Service::DockerRun::Gradle.new(dir, artifact_id:, package_version:).publish_and_install!
          end
        end

        shared_examples 'using a docker container' do |testcase|
          it 'pushes and pulls a maven package via gradle', testcase: testcase do
            project.visit!

            Page::Project::Menu.perform(&:go_to_package_registry)
            Page::Project::Packages::Index.perform do |index|
              expect(index).to have_package(package_name)

              index.click_package(package_name)
            end

            Page::Project::Packages::Show.perform do |show|
              expect(show).to have_package_info(name: nil, version: package_version)
            end
          end
        end

        context 'with a project deploy token' do
          let(:maven_header_name) { 'Deploy-Token' }
          let(:project_deploy_token) do
            create(:project_deploy_token,
              name: 'package-deploy-token',
              project: project,
              scopes: %w[
                read_repository
                read_package_registry
                write_package_registry
              ])
          end

          let(:token) { project_deploy_token.token }

          it_behaves_like 'using a docker container', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/562429'
        end

        context 'with a personal access token' do
          let(:maven_header_name) { 'Private-Token' }
          let(:token) { Runtime::User::Store.default_api_client.personal_access_token }

          it_behaves_like 'using a docker container', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/562423'
        end
      end
    end
  end
end
