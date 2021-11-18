# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :packages, :object_storage do
    describe 'Helm Registry' do
      include Runtime::Fixtures
      include_context 'packages registry qa scenario'

      let(:package_name) { "gitlab_qa_helm-#{SecureRandom.hex(8)}" }
      let(:package_version) { '1.3.7' }
      let(:package_type) { 'helm' }

      let(:package_gitlab_ci_file) do
        {
          file_path: '.gitlab-ci.yml',
          content:
              <<~YAML
                deploy:
                  image: alpine:3
                  script:
                    - apk add helm --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing
                    - apk add curl
                    - helm create #{package_name}
                    - cp ./Chart.yaml #{package_name}
                    - helm package #{package_name}
                    - http_code=$(curl --write-out "%{http_code}" --request POST --form 'chart=@#{package_name}-#{package_version}.tgz' --user #{username}:#{access_token} ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/helm/api/stable/charts --output /dev/null --silent)
                    - '[ $http_code = "201" ]'
                  only:
                    - "#{package_project.default_branch}"
                  tags:
                    - "runner-for-#{package_project.group.name}"
              YAML
        }
      end

      let(:package_chart_yaml_file) do
        {
          file_path: "Chart.yaml",
          content:
              <<~EOF
                apiVersion: v2
                name: #{package_name}
                description: GitLab QA helm package
                type: application
                version: #{package_version}
                appVersion: "1.16.0"
              EOF
        }
      end

      let(:client_gitlab_ci_file) do
        {
          file_path: '.gitlab-ci.yml',
          content:
              <<~YAML
                pull:
                  image: alpine:3
                  script:
                    - apk add helm --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing
                    - helm repo add --username #{username} --password #{access_token} gitlab_qa ${CI_API_V4_URL}/projects/#{package_project.id}/packages/helm/stable
                    - helm repo update
                    - helm pull gitlab_qa/#{package_name}
                  only:
                    - "#{client_project.default_branch}"
                  tags:
                    - "runner-for-#{client_project.group.name}"
              YAML
        }
      end

      %i[personal_access_token ci_job_token project_deploy_token].each do |authentication_token_type|
        context "using a #{authentication_token_type}" do
          let(:username) do
            case authentication_token_type
            when :personal_access_token
              Runtime::User.username
            when :ci_job_token
              'gitlab-ci-token'
            when :project_deploy_token
              project_deploy_token.username
            end
          end

          let(:access_token) do
            case authentication_token_type
            when :personal_access_token
              personal_access_token
            when :ci_job_token
              '${CI_JOB_TOKEN}'
            when :project_deploy_token
              project_deploy_token.password
            end
          end

          it "pushes and pulls a helm chart" do
            # pushing
            Resource::Repository::Commit.fabricate_via_api! do |commit|
              commit.project = package_project
              commit.commit_message = 'Add .gitlab-ci.yml'
              commit.add_files([package_gitlab_ci_file, package_chart_yaml_file])
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
              commit.add_files([client_gitlab_ci_file])
            end

            client_project.visit!

            Flow::Pipeline.visit_latest_pipeline

            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.click_job('pull')
            end

            Page::Project::Job::Show.perform do |job|
              expect(job).to be_successful(timeout: 800)
            end
          end
        end
      end
    end
  end
end
