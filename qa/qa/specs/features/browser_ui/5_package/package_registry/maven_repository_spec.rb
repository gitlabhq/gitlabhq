# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :packages, :object_storage do
    describe 'Maven Repository' do
      using RSpec::Parameterized::TableSyntax
      include Runtime::Fixtures
      include_context 'packages registry qa scenario'

      let(:group_id) { 'com.gitlab.qa' }
      let(:artifact_id) { "maven-#{SecureRandom.hex(8)}" }
      let(:package_name) { "#{group_id}/#{artifact_id}".tr('.', '/') }
      let(:package_version) { '1.3.7' }
      let(:package_type) { 'maven' }

      let(:package_gitlab_ci_file) do
        {
          file_path: '.gitlab-ci.yml',
          content:
              <<~YAML
                deploy:
                  image: maven:3.6-jdk-11
                  script:
                    - 'mvn deploy -s settings.xml'
                  only:
                    - "#{package_project.default_branch}"
                  tags:
                    - "runner-for-#{package_project.group.name}"
              YAML
        }
      end

      let(:package_pom_file) do
        {
          file_path: 'pom.xml',
          content: <<~XML
            <project>
              <groupId>#{group_id}</groupId>
              <artifactId>#{artifact_id}</artifactId>
              <version>#{package_version}</version>
              <modelVersion>4.0.0</modelVersion>
              <repositories>
                <repository>
                  <id>#{package_project.name}</id>
                  <url>#{gitlab_address_with_port}/api/v4/groups/#{package_project.group.id}/-/packages/maven</url>
                </repository>
              </repositories>
              <distributionManagement>
                <repository>
                  <id>#{package_project.name}</id>
                  <url>#{gitlab_address_with_port}/api/v4/projects/#{package_project.id}/packages/maven</url>
                </repository>
                <snapshotRepository>
                  <id>#{package_project.name}</id>
                  <url>#{gitlab_address_with_port}/api/v4/projects/#{package_project.id}/packages/maven</url>
                </snapshotRepository>
              </distributionManagement>
            </project>
          XML
        }
      end

      let(:client_gitlab_ci_file) do
        {
          file_path: '.gitlab-ci.yml',
          content:
              <<~YAML
                install:
                  image: maven:3.6-jdk-11
                  script:
                    - "mvn install -s settings.xml"
                  only:
                    - "#{client_project.default_branch}"
                  tags:
                    - "runner-for-#{client_project.group.name}"
              YAML
        }
      end

      let(:client_pom_file) do
        {
          file_path: 'pom.xml',
          content: <<~XML
            <project>
              <groupId>#{group_id}</groupId>
              <artifactId>maven_client</artifactId>
              <version>1.0</version>
              <modelVersion>4.0.0</modelVersion>
              <repositories>
                <repository>
                  <id>#{package_project.name}</id>
                  <url>#{gitlab_address_with_port}/api/v4/groups/#{package_project.group.id}/-/packages/maven</url>
                </repository>
              </repositories>
              <dependencies>
                <dependency>
                  <groupId>#{group_id}</groupId>
                  <artifactId>#{artifact_id}</artifactId>
                  <version>#{package_version}</version>
                </dependency>
              </dependencies>
            </project>
          XML
        }
      end

      let(:settings_xml_with_pat) do
        {
          file_path: 'settings.xml',
          content: <<~XML
            <settings xmlns="http://maven.apache.org/SETTINGS/1.1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.1.0 http://maven.apache.org/xsd/settings-1.1.0.xsd">
              <servers>
                <server>
                  <id>#{package_project.name}</id>
                  <configuration>
                    <httpHeaders>
                      <property>
                        <name>Private-Token</name>
                        <value>#{personal_access_token}</value>
                      </property>
                    </httpHeaders>
                  </configuration>
                </server>
              </servers>
            </settings>
          XML
        }
      end

      where(:authentication_token_type, :maven_header_name) do
        :personal_access_token | 'Private-Token'
        :ci_job_token          | 'Job-Token'
        :project_deploy_token  | 'Deploy-Token'
      end

      with_them do
        let(:token) do
          case authentication_token_type
          when :personal_access_token
            personal_access_token
          when :ci_job_token
            '${env.CI_JOB_TOKEN}'
          when :project_deploy_token
            project_deploy_token.password
          end
        end

        let(:settings_xml) do
          {
            file_path: 'settings.xml',
            content: <<~XML
              <settings xmlns="http://maven.apache.org/SETTINGS/1.1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.1.0 http://maven.apache.org/xsd/settings-1.1.0.xsd">
                <servers>
                  <server>
                    <id>#{package_project.name}</id>
                    <configuration>
                      <httpHeaders>
                        <property>
                          <name>#{maven_header_name}</name>
                          <value>#{token}</value>
                        </property>
                      </httpHeaders>
                    </configuration>
                  </server>
                </servers>
              </settings>
            XML
          }
        end

        it "pushes and pulls a maven package via maven using #{params[:authentication_token_type]}" do
          # pushing
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = package_project
            commit.commit_message = 'Add .gitlab-ci.yml'
            commit.add_files([
              package_gitlab_ci_file,
              package_pom_file,
              settings_xml
            ])
          end

          package_project.visit!

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

          Page::Project::Packages::Show.perform do |show|
            expect(show).to have_package_info(package_name, package_version)
          end

          # pulling
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = client_project
            commit.commit_message = 'Add .gitlab-ci.yml'
            commit.add_files([
              client_gitlab_ci_file,
              client_pom_file,
              settings_xml
            ])
          end

          client_project.visit!

          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('install')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end
        end

        context 'duplication setting' do
          before do
            package_project.group.visit!

            Page::Group::Menu.perform(&:go_to_package_settings)
          end

          context 'when disabled' do
            before do
              Page::Group::Settings::PackageRegistries.perform(&:set_allow_duplicates_disabled)
            end

            it "prevents users from publishing group level Maven packages duplicates using #{params[:authentication_token_type]}" do
              create_duplicated_package

              push_duplicated_package

              client_project.visit!

              show_latest_deploy_job

              Page::Project::Job::Show.perform do |job|
                expect(job).not_to be_successful(timeout: 800)
              end
            end
          end

          context 'when enabled' do
            before do
              Page::Group::Settings::PackageRegistries.perform(&:set_allow_duplicates_enabled)
            end

            it "allows users to publish group level Maven packages duplicates using #{params[:authentication_token_type]}" do
              create_duplicated_package

              push_duplicated_package

              show_latest_deploy_job

              Page::Project::Job::Show.perform do |job|
                expect(job).to be_successful(timeout: 800)
              end
            end
          end

          def create_duplicated_package
            with_fixtures([package_pom_file, settings_xml_with_pat]) do |dir|
              Service::DockerRun::Maven.new(dir).publish!
            end

            package_project.visit!

            Page::Project::Menu.perform(&:click_packages_link)

            Page::Project::Packages::Index.perform do |index|
              expect(index).to have_package(package_name)
            end
          end

          def push_duplicated_package
            Resource::Repository::Commit.fabricate_via_api! do |commit|
              commit.project = client_project
              commit.commit_message = 'Add .gitlab-ci.yml'
              commit.add_files([
                package_gitlab_ci_file,
                package_pom_file,
                settings_xml
              ])
            end
          end

          def show_latest_deploy_job
            client_project.visit!

            Flow::Pipeline.visit_latest_pipeline

            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.click_job('deploy')
            end
          end
        end
      end
    end
  end
end
