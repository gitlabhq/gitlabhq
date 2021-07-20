# frozen_string_literal: true

require 'securerandom'

module QA
  RSpec.describe 'Package', :orchestrated, :packages, :reliable, :object_storage do
    describe 'Maven Repository' do
      include Runtime::Fixtures

      let(:group_id) { 'com.gitlab.qa' }
      let(:artifact_id) { "maven-#{SecureRandom.hex(8)}" }
      let(:another_artifact_id) { "maven-#{SecureRandom.hex(8)}" }
      let(:package_name) { "#{group_id}/#{artifact_id}".tr('.', '/') }
      let(:auth_token) do
        unless Page::Main::Menu.perform(&:signed_in?)
          Flow::Login.sign_in
        end

        Resource::PersonalAccessToken.fabricate!.token
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'maven-package-project'
        end
      end

      let(:another_project) do
        Resource::Project.fabricate_via_api! do |another_project|
          another_project.name = 'another-maven-package-project'
          another_project.group = project.group
        end
      end

      let(:package) do
        Resource::Package.init do |package|
          package.name = package_name
          package.project = project
        end
      end

      let!(:runner) do
        Resource::Runner.fabricate! do |runner|
          runner.name = "qa-runner-#{Time.now.to_i}"
          runner.tags = ["runner-for-#{project.group.name}"]
          runner.executor = :docker
          runner.token = project.group.runners_token
        end
      end

      let!(:gitlab_address_with_port) do
        uri = URI.parse(Runtime::Scenario.gitlab_address)
        "#{uri.scheme}://#{uri.host}:#{uri.port}"
      end

      let(:pom_xml) do
        {
          file_path: 'pom.xml',
          content: <<~XML
            <project>
              <groupId>#{group_id}</groupId>
              <artifactId>#{artifact_id}</artifactId>
              <version>1.0</version>
              <modelVersion>4.0.0</modelVersion>
              <repositories>
                <repository>
                  <id>#{project.name}</id>
                  <url>#{gitlab_address_with_port}/api/v4/groups/#{project.group.id}/-/packages/maven</url>
                </repository>
              </repositories>
              <distributionManagement>
                <repository>
                  <id>#{project.name}</id>
                  <url>#{gitlab_address_with_port}/api/v4/projects/#{project.id}/packages/maven</url>
                </repository>
                <snapshotRepository>
                  <id>#{project.name}</id>
                  <url>#{gitlab_address_with_port}/api/v4/projects/#{project.id}/packages/maven</url>
                </snapshotRepository>
              </distributionManagement>
            </project>
          XML
        }
      end

      let(:pom_xml_another_project) do
        {
          file_path: 'pom.xml',
          content: <<~XML
            <project>
              <groupId>#{group_id}</groupId>
              <artifactId>#{another_artifact_id}</artifactId>
              <version>1.0</version>
              <modelVersion>4.0.0</modelVersion>
              <repositories>
                <repository>
                  <id>#{another_project.name}</id>
                  <url>#{gitlab_address_with_port}/api/v4/groups/#{another_project.group.id}/-/packages/maven</url>
                </repository>
              </repositories>
              <distributionManagement>
                <repository>
                  <id>#{another_project.name}</id>
                  <url>#{gitlab_address_with_port}/api/v4/projects/#{another_project.id}/packages/maven</url>
                </repository>
                <snapshotRepository>
                  <id>#{another_project.name}</id>
                  <url>#{gitlab_address_with_port}/api/v4/projects/#{another_project.id}/packages/maven</url>
                </snapshotRepository>
              </distributionManagement>
              <dependencies>
                <dependency>
                  <groupId>#{group_id}</groupId>
                  <artifactId>#{artifact_id}</artifactId>
                  <version>1.0</version>
                </dependency>
              </dependencies>
            </project>
          XML
        }
      end

      let(:settings_xml) do
        {
          file_path: 'settings.xml',
          content: <<~XML
            <settings xmlns="http://maven.apache.org/SETTINGS/1.1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.1.0 http://maven.apache.org/xsd/settings-1.1.0.xsd">
              <servers>
                <server>
                  <id>#{project.name}</id>
                  <configuration>
                    <httpHeaders>
                      <property>
                        <name>Private-Token</name>
                        <value>#{auth_token}</value>
                      </property>
                    </httpHeaders>
                  </configuration>
                </server>
              </servers>
            </settings>
          XML
        }
      end

      let(:gitlab_ci_deploy_yml) do
        {
          file_path: '.gitlab-ci.yml',
          content:
              <<~YAML
                deploy:
                  image: maven:3.6-jdk-11
                  script:
                    - 'mvn deploy -s settings.xml'
                    - "mvn dependency:get -Dartifact=#{group_id}:#{artifact_id}:1.0"
                  only:
                    - "#{project.default_branch}"
                  tags:
                    - "runner-for-#{project.group.name}"
              YAML
        }
      end

      let(:gitlab_ci_install_yml) do
        {
          file_path: '.gitlab-ci.yml',
          content:
              <<~YAML
                install:
                  image: maven:3.6-jdk-11
                  script:
                    - "mvn install"
                  only:
                    - "#{project.default_branch}"
                  tags:
                    - "runner-for-#{another_project.group.name}"
              YAML
        }
      end

      after do
        runner.remove_via_api!
        project.remove_via_api!
        another_project.remove_via_api!
      end

      it 'pushes and pulls a Maven package via CI and deletes it', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1115' do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files([
                             gitlab_ci_deploy_yml,
                             settings_xml,
                             pom_xml
          ])
        end

        project.visit!
        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('deploy')
        end

        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 800)
        end

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = another_project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files([
                             gitlab_ci_install_yml,
                             pom_xml_another_project
          ])
        end

        another_project.visit!
        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('install')
        end

        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 800)
        end

        project.visit!

        Page::Project::Menu.perform(&:click_packages_link)

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_package(package_name)

          index.click_package(package_name)
        end

        Page::Project::Packages::Show.perform do |show|
          expect(show).to have_package_info(package_name, "1.0")
          show.click_delete
        end

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_content("Package deleted successfully")
          expect(index).not_to have_package(package_name)
        end
      end

      context 'when "allow duplicate" setting is disabled' do
        before do
          Flow::Login.sign_in

          project.group.visit!

          Page::Group::Menu.perform(&:go_to_package_settings)
          Page::Group::Settings::PackageRegistries.perform(&:set_allow_duplicates_disabled)
        end

        it 'prevents users from publishing duplicate Maven packages at the group level', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1717' do
          with_fixtures([pom_xml, settings_xml]) do |dir|
            Service::DockerRun::Maven.new(dir).publish!
          end

          project.visit!
          Page::Project::Menu.perform(&:click_packages_link)

          Page::Project::Packages::Index.perform do |index|
            expect(index).to have_package(package_name)
          end

          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = another_project
            commit.commit_message = 'Add .gitlab-ci.yml'
            commit.add_files([
                                 gitlab_ci_deploy_yml,
                                 settings_xml,
                                 pom_xml
                             ])
          end

          another_project.visit!
          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('deploy')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).not_to be_successful(timeout: 800)
          end
        end
      end

      context 'when "allow duplicate" setting is enabled' do
        before do
          Flow::Login.sign_in

          project.group.visit!

          Page::Group::Menu.perform(&:go_to_package_settings)
          Page::Group::Settings::PackageRegistries.perform(&:set_allow_duplicates_enabled)
        end

        it 'allows users to publish duplicate Maven packages at the group level', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1722' do
          with_fixtures([pom_xml, settings_xml]) do |dir|
            Service::DockerRun::Maven.new(dir).publish!
          end

          project.visit!
          Page::Project::Menu.perform(&:click_packages_link)

          Page::Project::Packages::Index.perform do |index|
            expect(index).to have_package(package_name)
          end

          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = another_project
            commit.commit_message = 'Add .gitlab-ci.yml'
            commit.add_files([
                                 gitlab_ci_deploy_yml,
                                 settings_xml,
                                 pom_xml
                             ])
          end

          another_project.visit!
          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('deploy')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end
        end
      end
    end
  end
end
