# frozen_string_literal: true

module QA
  shared_examples 'code owner merge request' do
    let(:branch_name) { 'new-branch' }

    it 'is approved and merged' do
      # Require one approval from any eligible user on any branch
      # This will confirm that this type of unrestricted approval is
      # also satisfied when a code owner grants approval
      Page::Project::Menu.perform(&:go_to_general_settings)
      Page::Project::Settings::Main.perform do |main|
        main.expand_merge_request_approvals_settings do |settings|
          settings.set_default_number_of_approvals_required(1)
        end
      end

      Resource::Repository::Commit.fabricate_via_api! do |commit|
        commit.project = project
        commit.commit_message = 'Add CODEOWNERS'
        commit.add_files(
          [
            {
              file_path: 'CODEOWNERS',
              content: <<~CONTENT
                README.md @#{codeowner}
              CONTENT
            }
          ]
        )
      end

      # Require approval from code owners on master
      Resource::ProtectedBranch.fabricate! do |protected_branch|
        protected_branch.project = project
        protected_branch.branch_name = 'master'
        protected_branch.new_branch = false
        protected_branch.require_code_owner_approval = true
      end

      # Push a change to the file with a CODEOWNERS rule
      Resource::Repository::Push.fabricate! do |push|
        push.repository_http_uri = project.repository_http_location.uri
        push.branch_name = branch_name
        push.file_name = 'README.md'
        push.file_content = 'Updated'
      end

      merge_request = Resource::MergeRequest.fabricate! do |merge_request|
        merge_request.project = project
        merge_request.target_new_branch = false
        merge_request.source_branch = branch_name
        merge_request.no_preparation = true
      end

      Flow::Login.while_signed_in(as: approver) do
        merge_request.visit!

        Page::MergeRequest::Show.perform do |merge_request|
          expect(merge_request.approvals_required_from).to include('Code Owners')
          expect(merge_request).not_to be_mergeable

          merge_request.click_approve
          merge_request.merge!

          expect(merge_request).to be_merged
        end
      end
    end
  end
end
