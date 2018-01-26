module QA
  feature 'merge request squash commits', :core do
    scenario 'when squash commits is marked before merge'  do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      merge_request =
        Factory::Resource::MergeRequest.fabricate! do |merge_request|
          merge_request.title = 'Squashing commits'
        end

      Factory::Repository::Push.fabricate! do |push|
        push.project = merge_request.project
        push.commit_message = 'to be squashed'
        push.branch_name = merge_request.source_branch
        push.new_branch = false
        push.file_name = 'other.txt'
      end

      merge_request.visit!

      Page::MergeRequest::Show.perform do |merge_request_page|
        merge_request_page.mark_to_squash
        merge_request_page.merge!

        merge_request.project.visit!

        Git::Repository.perform do |repository|
          repository.location = Page::Project::Show.act do
            choose_repository_clone_http
            repository_location
          end

          repository.use_default_credentials

          repository.act { clone }

          expect(repository.commits.size).to eq 3
        end
      end
    end
  end
end
