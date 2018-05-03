module QA
  feature 'merge request squash commits', :core do
    scenario 'when squash commits is marked before merge'  do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      project = Factory::Resource::Project.fabricate! do |project|
        project.name = "squash-before-merge"
      end

      merge_request = Factory::Resource::MergeRequest.fabricate! do |merge_request|
        merge_request.project = project
        merge_request.title = 'Squashing commits'
      end

      Factory::Repository::Push.fabricate! do |push|
        push.project = project
        push.commit_message = 'to be squashed'
        push.branch_name = merge_request.source_branch
        push.new_branch = false
        push.file_name = 'other.txt'
        push.file_content = "Test with unicode characters ❤✓€❄"
      end

      merge_request.visit!

      Page::MergeRequest::Show.perform do |merge_request_page|
        merge_request_page.mark_to_squash
        merge_request_page.merge!

        merge_request.project.visit!

        Git::Repository.perform do |repository|
          repository.uri = Page::Project::Show.act do
            choose_repository_clone_http
            repository_location.uri
          end

          repository.use_default_credentials

          repository.act { clone }

          expect(repository.commits.size).to eq 3
        end
      end
    end
  end
end
