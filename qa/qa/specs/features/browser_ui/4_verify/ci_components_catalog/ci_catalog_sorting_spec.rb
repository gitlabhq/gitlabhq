# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', product_group: :pipeline_authoring do
    describe 'CI catalog', :skip_live_env do
      let(:project_count) { 3 }

      let(:catalog_project_list) do
        create_list(
          :project,
          project_count,
          :with_readme,
          name: 'project-for-catalog',
          description: 'This is a catalog project.'
        )
      end

      let(:tag) { '1.0.0' }
      let(:test_project_names) { catalog_project_list.map(&:name) }

      shared_examples 'descending order by default' do |testcase|
        it 'displays from last to first', testcase: testcase do
          Page::Explore::CiCdCatalog.perform do |catalog|
            expect(top_projects_from_ui(catalog)).to eql(test_project_names.reverse)
          end
        end
      end

      shared_examples 'ascending order' do |testcase|
        it 'displays from first to last', testcase: testcase do
          Page::Explore::CiCdCatalog.perform do |catalog|
            catalog.sort_in_ascending_order
            expect(bottom_projects_from_ui(catalog)).to eql(test_project_names)
          end
        end
      end

      context 'when sorting' do
        before do
          Flow::Login.sign_in

          catalog_project_list.each do |project|
            Flow::Project.enable_catalog_resource_feature(project)
            setup_component(project)
            create_release(project)
          end

          Page::Main::Menu.perform do |main|
            main.go_to_explore
            main.go_to_ci_cd_catalog
          end
        end

        context(
          'with released at',
          quarantine: {
            type: :stale,
            issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/468679'
          }
        ) do
          it_behaves_like 'descending order by default',
            'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/441478'

          it_behaves_like 'ascending order',
            'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/441477'
        end

        context 'with created at' do
          before do
            Page::Explore::CiCdCatalog.perform(&:sort_by_created_at)
          end

          it_behaves_like 'descending order by default',
            'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/441479'

          it_behaves_like 'ascending order',
            'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/441475'
        end
      end

      private

      def setup_component(project)
        create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml and component', actions: [
          {
            action: 'create',
            file_path: '.gitlab-ci.yml',
            content: <<~YAML
              create-release:
                stage: deploy
                script: echo "Creating release $CI_COMMIT_TAG"
                rules:
                  - if: $CI_COMMIT_TAG
              release:
                tag_name: $CI_COMMIT_TAG
                description: "Release $CI_COMMIT_TAG of components in $CI_PROJECT_PATH"
            YAML
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

      def create_release(project)
        project.create_release(tag)
      end

      def top_projects_from_ui(page_object)
        page_object.get_top_project_names(project_count)
      end

      def bottom_projects_from_ui(page_object)
        page_object.get_bottom_project_names(project_count)
      end
    end
  end
end
