# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :packages, :object_storage do
    describe 'Maven project level endpoint' do
      using RSpec::Parameterized::TableSyntax

      let(:group_id) { 'com.gitlab.qa' }
      let(:artifact_id) { "maven-#{SecureRandom.hex(8)}" }
      let(:package_name) { "#{group_id}/#{artifact_id}".tr('.', '/') }
      let(:package_version) { '1.3.7' }
      let(:package_type) { 'maven' }
      let(:personal_access_token) { Runtime::Env.personal_access_token }

      let(:package_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = "#{package_type}_package_project"
          project.initialize_with_readme = true
          project.visibility = :private
        end
      end

      let(:package) do
        Resource::Package.init do |package|
          package.name = package_name
          package.project = package_project
        end
      end

      let(:runner) do
        Resource::Runner.fabricate! do |runner|
          runner.name = "qa-runner-#{Time.now.to_i}"
          runner.tags = ["runner-for-#{package_project.name}"]
          runner.executor = :docker
          runner.project = package_project
        end
      end

      let(:gitlab_address_with_port) do
        uri = URI.parse(Runtime::Scenario.gitlab_address)
        "#{uri.scheme}://#{uri.host}:#{uri.port}"
      end

      let(:project_deploy_token) do
        Resource::ProjectDeployToken.fabricate_via_api! do |deploy_token|
          deploy_token.name = 'package-deploy-token'
          deploy_token.project = package_project
          deploy_token.scopes = %w[
            read_repository
            read_package_registry
            write_package_registry
          ]
        end
      end

      let(:gitlab_ci_file) do
        {
          file_path: '.gitlab-ci.yml',
          content:
              <<~YAML
                deploy-and-install:
                  image: maven:3.6-jdk-11
                  script:
                    - 'mvn deploy -s settings.xml'
                    - 'mvn install -s settings.xml'
                  only:
                    - "#{package_project.default_branch}"
                  tags:
                    - "runner-for-#{package_project.name}"
              YAML
        }
      end

      let(:pom_file) do
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
                  <url>#{gitlab_address_with_port}/api/v4/projects/#{package_project.id}/-/packages/maven</url>
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

      before do
        Flow::Login.sign_in_unless_signed_in
        runner
      end

      after do
        runner.remove_via_api!
        package.remove_via_api!
        package_project.remove_via_api!
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
            project_deploy_token.token
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
          Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
            Resource::Repository::Commit.fabricate_via_api! do |commit|
              commit.project = package_project
              commit.commit_message = 'Add .gitlab-ci.yml'
              commit.add_files([
                gitlab_ci_file,
                pom_file,
                settings_xml
              ])
            end
          end

          package_project.visit!

          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('deploy')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)

            job.click_element(:pipeline_path)
          end

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('install')
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
        end
      end
    end
  end
end
