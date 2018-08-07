module QA
  describe 'merge request rebase' do
    it 'rebases source branch of merge request'  do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      project = Factory::Resource::Project.fabricate! do |project|
        project.name = "only-fast-forward"
      end

      Page::Menu::Side.act { go_to_settings }
      Page::Project::Settings::MergeRequest.act { enable_ff_only }

      merge_request = Factory::Resource::MergeRequest.fabricate! do |merge_request|
        merge_request.project = project
        merge_request.title = 'Needs rebasing'
      end

      Factory::Repository::ProjectPush.fabricate! do |push|
        push.project = project
        push.file_name = "other.txt"
        push.file_content = "New file added!"
        push.branch_name = "master"
        push.new_branch = false
      end

      merge_request.visit!

      Page::MergeRequest::Show.perform do |merge_request|
        expect(merge_request).to have_content('Needs rebasing')
        expect(merge_request).not_to be_fast_forward_possible
        expect(merge_request).not_to have_merge_button

        merge_request.rebase!

        expect(merge_request).to have_merge_button
        expect(merge_request.fast_forward_possible?).to be_truthy
      end
    end
  end
end
