# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'Merge request squashing' do
      it 'user squashes commits while merging' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        project = Resource::Project.fabricate! do |project|
          project.name = "squash-before-merge"
        end

        merge_request = Resource::MergeRequest.fabricate! do |merge_request|
          merge_request.project = project
          merge_request.title = 'Squashing commits'
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.commit_message = 'to be squashed'
          push.branch_name = merge_request.source_branch
          push.new_branch = false
          push.file_name = 'other.txt'
          push.file_content = "Test with unicode characters ❤✓€❄"
        end

        Page::Project::Show.perform(&:wait_for_push)
        merge_request.visit!

        expect(page).to have_text('to be squashed')

        Page::MergeRequest::Show.perform do |merge_request_page|
          merge_request_page.mark_to_squash
          merge_request_page.merge!

          merge_request.project.visit!

          Git::Repository.perform do |repository|
            repository.uri = Page::Project::Show.act do
              repository_clone_http_location.uri
            end

            repository.use_default_credentials

            repository.clone

            expect(repository.commits.size).to eq 3
          end
        end
      end
    end
  end
end
