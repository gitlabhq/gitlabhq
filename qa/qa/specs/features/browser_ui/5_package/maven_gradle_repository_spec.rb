# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :packages do
    describe 'Maven Repository with Gradle' do
      include Runtime::Fixtures

      let(:group_id) { 'com.gitlab.qa' }
      let(:artifact_id) { 'maven_gradle' }
      let(:package_name) { "#{group_id}/#{artifact_id}".tr('.', '/') }
      let(:auth_token) do
        unless Page::Main::Menu.perform(&:signed_in?)
          Flow::Login.sign_in
        end

        Resource::PersonalAccessToken.fabricate!.token
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'maven-with-gradle-project'
          project.initialize_with_readme = true
        end
      end

      let(:package) do
        Resource::Package.new.tap do |package|
          package.name = package_name
          package.project = project
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

      let(:gitlab_address_with_port) do
        uri = URI.parse(Runtime::Scenario.gitlab_address)
        "#{uri.scheme}://#{uri.host}:#{uri.port}"
      end

      after do
        runner.remove_via_api!
        package.remove_via_api!
      end

      it 'publishes a maven package via gradle', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1074' do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files([{
                                file_path: '.gitlab-ci.yml',
                                content:
                                    <<~YAML
                                      deploy:
                                        image: gradle:6.5-jdk11
                                        script:
                                        - 'gradle publish'
                                        only:
                                        - "#{project.default_branch}"
                                        tags:
                                        - "runner-for-#{project.name}"
                                    YAML
                            },
                            {
                                file_path: 'build.gradle',
                                content:
                                    <<~EOF
                                      plugins {
                                          id 'java'
                                          id 'maven-publish'
                                      }

                                      publishing {
                                          publications {
                                              library(MavenPublication) {
                                                  groupId '#{group_id}'
                                                  artifactId '#{artifact_id}'
                                                  from components.java
                                              }
                                          }
                                          repositories {
                                              maven {
                                                  url "#{gitlab_address_with_port}/api/v4/projects/#{project.id}/packages/maven"
                                                  credentials(HttpHeaderCredentials) {
                                                      name = "Private-Token"
                                                      value = "#{auth_token}"
                                                  }
                                                  authentication {
                                                      header(HttpHeaderAuthentication)
                                                  }
                                              }
                                          }
                                      }
                                    EOF
                            }])
        end

        project.visit!
        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('deploy')
        end

        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 800)
        end

        Page::Project::Menu.perform(&:click_packages_link)

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_package(package_name)

          index.click_package(package_name)
        end

        Page::Project::Packages::Show.perform(&:click_delete)

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_content("Package deleted successfully")
          expect(index).not_to have_package(package_name)
        end
      end
    end
  end
end
