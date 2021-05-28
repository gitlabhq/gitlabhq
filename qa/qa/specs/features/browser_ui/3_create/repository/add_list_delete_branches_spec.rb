# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Create, list, and delete branches via web', :requires_admin do
      master_branch = nil
      second_branch = 'second-branch'
      third_branch = 'third-branch'
      file_1_master = 'file.txt'
      file_2_master = 'other-file.txt'
      file_second_branch = 'file-2.txt'
      file_third_branch = 'file-3.txt'
      first_commit_message_of_master_branch = "Add #{file_1_master}"
      second_commit_message_of_master_branch = "Add #{file_2_master}"
      commit_message_of_second_branch = "Add #{file_second_branch}"
      commit_message_of_third_branch = "Add #{file_third_branch}"

      before do
        Flow::Login.sign_in

        project = Resource::Project.fabricate_via_api! do |proj|
          proj.name = 'project-qa-test'
          proj.description = 'project for qa test'
          proj.initialize_with_readme = true
        end

        Runtime::Feature.enable(:delete_branch_confirmation_modals, project: project)

        master_branch = project.default_branch

        Git::Repository.perform do |repository|
          repository.uri = project.repository_http_location.uri
          repository.use_default_credentials
          repository.try_add_credentials_to_netrc
          repository.default_branch = master_branch

          repository.act do
            clone
            configure_identity('GitLab QA', 'root@gitlab.com')
            commit_file(file_1_master, 'Test file content', first_commit_message_of_master_branch)
            push_changes
            checkout(second_branch, new_branch: true)
            commit_file(file_second_branch, 'File 2 content', commit_message_of_second_branch)
            push_changes(second_branch)
            checkout(master_branch)
            # This second commit on master is needed for the master branch to be ahead
            # of the second branch, and when the second branch is merged to master it will
            # show the 'merged' badge on it.
            # Refer to the below issue note:
            # https://gitlab.com/gitlab-org/gitlab-foss/issues/55524#note_126100848
            commit_file(file_2_master, 'Other test file content', second_commit_message_of_master_branch)
            push_changes
            merge(second_branch)
            push_changes
            checkout(third_branch, new_branch: true)
            commit_file(file_third_branch, 'File 3 content', commit_message_of_third_branch)
            push_changes(third_branch)
          end
        end
        project.wait_for_push commit_message_of_third_branch
        project.visit!
      end

      it 'lists branches correctly after CRUD operations', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1688' do
        Page::Project::Menu.perform(&:go_to_repository_branches)

        expect(page).to have_content(master_branch)
        expect(page).to have_content(second_branch)
        expect(page).to have_content(third_branch)
        expect(page).to have_content("Merge branch 'second-branch'")
        expect(page).to have_content(commit_message_of_second_branch)
        expect(page).to have_content(commit_message_of_third_branch)

        Page::Project::Branches::Show.perform do |branches_page|
          expect(branches_page).to have_branch_with_badge(second_branch, 'merged')

          branches_page.delete_branch(third_branch)

          expect(branches_page).to have_no_branch(third_branch)

          branches_page.delete_merged_branches

          expect(branches_page).to have_content(
            'Merged branches are being deleted. This can take some time depending on the number of branches. Please refresh the page to see changes.'
          )

          branches_page.refresh

          expect(branches_page).to have_no_branch(second_branch, reload: true)
        end
      end
    end
  end
end
