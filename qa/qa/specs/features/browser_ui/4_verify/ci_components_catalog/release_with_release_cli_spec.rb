# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', product_group: :pipeline_authoring, feature_flag: {
    name: :ci_release_cli_catalog_publish_option
  } do
    describe 'CI catalog release with release-cli', :skip_live_env do
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }

      let!(:project) do
        create(:project, :with_readme, name: 'component-project', description: 'This is a project with CI component.')
      end

      let!(:milestone1) { create(:project_milestone, project: project, title: 'v1.0') }
      let!(:milestone2) { create(:project_milestone, project: project, title: 'v2.0') }

      let!(:runner) { create(:project_runner, project: project, name: executor, tags: [executor], executor: :docker) }

      before do
        Runtime::Feature.disable(:ci_release_cli_catalog_publish_option)

        Flow::Login.sign_in
        Flow::Project.enable_catalog_resource_feature(project)
      end

      after do
        runner.remove_via_api!
      end

      it 'creates a release with existing tag',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/511345' do
        setup_component(project, gitlab_ci_yaml_for_create_release_with_existing_tag)
        project.create_repository_tag('1.0.0')

        project.visit!
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
        project.visit_job('create-release-with-existing-tag')

        Page::Project::Job::Show.perform do |show|
          Support::Waiter.wait_until { show.has_passed? }

          aggregate_failures 'Job has expected contents' do
            expect(show.output).to have_content('release created successfully!')
            expect(show.output).to have_content('Tag: 1.0.0')
            expect(show.output).to have_content('Name: 1.0.0')
            expect(show.output).to have_content('Description: A long description of the release')
          end
        end

        visit_catalog_resource_show_page

        Page::Explore::CiCdCatalog::Show.perform do |show|
          aggregate_failures 'Catalog component has expected contents' do
            expect(show).to have_version_badge('1.0.0')
            expect(show).to have_component_name('new_component')
            expect(show).to have_input(
              name: 'scanner-output',
              required: 'false',
              type: 'string',
              description: '',
              default: 'json'
            )
          end

          show.click_latest_version_badge
        end

        Page::Project::Tag::Show.perform do |show|
          aggregate_failures 'Project tag has expected contents' do
            expect(show).to have_tag_name('1.0.0')
            expect(show).to have_no_tag_message
          end

          show.click_release_link
        end

        Page::Project::Release::Show.perform do |show|
          aggregate_failures 'Project release has expected contents' do
            expect(show).to have_release_name('1.0.0')
            expect(show).to have_release_description('A long description of the release')
          end
        end
      end

      it 'creates a release with new tag filled with information',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/512398' do
        setup_component(project, gitlab_ci_yaml_for_create_release_with_new_tag_filled_with_information)
        project.create_repository_tag('1.0.0')

        project.visit!
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
        project.visit_job('create-release-with-new-tag-filled-with-information')

        Page::Project::Job::Show.perform do |show|
          Support::Waiter.wait_until { show.has_passed? }

          aggregate_failures 'Job has expected contents' do
            expect(show.output).to have_content('release created successfully!')
            expect(show.output).to have_content('Tag: v9.0.2')
            expect(show.output).to have_content('Name: new release v9.0.2')
            expect(show.output).to have_content('Description: A long description of the release')
            expect(show.output).to have_content('Released At: 2026-01-01 00:00:00 +0000 UTC')
            expect(show.output).to have_content('Asset::Link::Name: Download link')
            expect(show.output).to have_content('Asset::Link::URL: https://gitlab-runner-downloads.s3.amazonaws.com/v16.9.0-rc2/binaries/gitlab-runner-linux-amd64')
            expect(show.output).to have_content('Milestone: v1.0 -')
            expect(show.output).to have_content('Milestone: v2.0 -')
          end
        end

        visit_catalog_resource_show_page

        Page::Explore::CiCdCatalog::Show.perform do |show|
          aggregate_failures 'Catalog component has expected contents' do
            expect(show).to have_version_badge('9.0.2')
            expect(show).to have_component_name('new_component')
            expect(show).to have_input(
              name: 'scanner-output',
              required: 'false',
              type: 'string',
              description: '',
              default: 'json'
            )
          end

          show.click_latest_version_badge
        end

        Page::Project::Tag::Show.perform do |show|
          aggregate_failures 'Project tag has expected contents' do
            expect(show).to have_tag_name('v9.0.2')
            expect(show).to have_tag_message('a new tag')
          end

          show.click_release_link
        end

        Page::Project::Release::Show.perform do |show|
          aggregate_failures 'Project release has expected contents' do
            expect(show).to have_release_name('new release v9.0.2')
            expect(show).to have_release_description('A long description of the release')
            expect(show).to have_milestone_title('v1.0')
            expect(show).to have_milestone_title('v2.0')
            expect(show).to have_asset_link('Download link', '/binaries/gitlab-runner-linux-amd64')
          end
        end
      end

      private

      def setup_component(project, ci_yaml)
        create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml and component', actions: [
          {
            action: 'create',
            file_path: '.gitlab-ci.yml',
            content: ci_yaml
          },
          {
            action: 'create',
            file_path: 'templates/new_component.yml',
            content: <<~YAML
              spec:
                inputs:
                  scanner-output:
                    default: json
              ---
              my-scanner:
                script: my-scan --output $[[ inputs.scanner-output ]]
            YAML
          }
        ])
      end

      def gitlab_ci_yaml_for_create_release_with_existing_tag
        <<~YAML
          default:
            tags: ["#{executor}"]

          create-release-with-existing-tag:
            image: registry.gitlab.com/gitlab-org/release-cli:latest
            script:
              - echo "Creating release $CI_COMMIT_TAG"
            rules:
              - if: $CI_COMMIT_TAG
            release:
              tag_name: $CI_COMMIT_TAG
              description: "A long description of the release"
        YAML
      end

      def gitlab_ci_yaml_for_create_release_with_new_tag_filled_with_information
        <<~YAML
          default:
            tags: ["#{executor}"]

          workflow:
            rules:
              - if: $CI_COMMIT_TAG != "v9.0.2" # to prevent creating a new pipeline because of the tag created in the test

          create-release-with-new-tag-filled-with-information:
            image: registry.gitlab.com/gitlab-org/release-cli:latest
            script:
              - echo "Creating release $CI_COMMIT_TAG"
            rules:
              - if: $CI_COMMIT_TAG
            release:
              name: "new release v9.0.2"
              description: "A long description of the release"
              tag_name: v9.0.2
              tag_message: a new tag
              ref: $CI_COMMIT_TAG
              milestones: ["v1.0", "v2.0"]
              released_at: "2026-01-01T00:00:00Z"
              assets:
                links:
                  - name: "Download link"
                    url: "https://gitlab-runner-downloads.s3.amazonaws.com/v16.9.0-rc2/binaries/gitlab-runner-linux-amd64"
                    filepath: "/binaries/gitlab-runner-linux-amd64"
                    link_type: "other"
        YAML
      end

      def visit_catalog_resource_show_page
        Page::Main::Menu.perform do |main|
          main.go_to_explore
          main.go_to_ci_cd_catalog
        end

        Page::Explore::CiCdCatalog.perform do |catalog|
          catalog.click_resource_link(project.name)
        end
      end
    end
  end
end
