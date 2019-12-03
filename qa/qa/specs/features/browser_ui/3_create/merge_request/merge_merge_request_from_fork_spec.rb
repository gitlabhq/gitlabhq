# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'Merge request creation from fork' do
      it 'user forks a project, submits a merge request and maintainer merges it' do
        Flow::Login.sign_in

        merge_request = Resource::MergeRequestFromFork.fabricate! do |merge_request|
          merge_request.fork_branch = 'feature-branch'
        end

        Page::Main::Menu.perform(&:sign_out)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        merge_request.visit!

        Page::MergeRequest::Show.perform(&:merge!)

        expect(page).to have_content('The changes were merged')
      end
    end
  end
end
