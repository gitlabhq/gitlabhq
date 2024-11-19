# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :github, :requires_admin, product_group: :import_and_integrate do
    describe 'GitHub import',
      quarantine: {
        type: :investigating,
        issue: "https://gitlab.com/gitlab-org/gitlab/-/issues/452419"
      } do
      include_context 'with github import'

      context 'when imported via UI' do
        let(:imported_project) do
          Resource::ProjectImportedFromGithub.init do |project|
            project.import = true
            project.group = group
            project.github_personal_access_token = Runtime::Env.github_access_token
            project.github_repository_path = github_repo
            project.api_client = admin_api_client
          end
        end

        let(:imported_issue) do
          build(:issue,
            project: imported_project,
            iid: imported_project.issues.first[:iid],
            api_client: admin_api_client).reload!
        end

        let(:imported_issue_events) do
          imported_issue.label_events.map { |e| { name: "#{e[:action]}_label", label: e.dig(:label, :name) } }
        end

        before do
          QA::Support::Helpers::ImportSource.enable('github')

          Flow::Login.sign_in(as: user)
          Page::Main::Menu.perform(&:go_to_create_project)
          Page::Project::New.perform do |project_page|
            project_page.click_import_project
            project_page.click_github_link
          end
        end

        it 'imports a project', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347877' do
          Page::Project::Import::Github.perform do |import_page|
            import_page.add_personal_access_token(Runtime::Env.github_access_token)

            import_page.select_advanced_option(:single_endpoint_notes_import)
            import_page.select_advanced_option(:attachments_import)

            import_page.import!(github_repo, group.full_path, imported_project.name)

            aggregate_failures do
              expect(import_page).to have_imported_project(github_repo, wait: import_wait_duration)
              # validate link is present instead of navigating to avoid dealing with multiple tabs
              # which makes the test more complicated
              expect(import_page).to have_go_to_project_link(github_repo)
            end
          end

          imported_project.reload!.visit!
          Page::Project::Show.perform do |project|
            aggregate_failures do
              expect(project).to have_content(imported_project.name)
              expect(project).to have_content('Project for github import test')
            end
          end

          expect(imported_issue_events).to match_array(
            [
              { name: "add_label", label: "question" },
              { name: "add_label", label: "good first issue" },
              { name: "add_label", label: "help wanted" }
            ]
          )
        end
      end
    end
  end
end
