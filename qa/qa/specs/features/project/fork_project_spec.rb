module QA
  describe 'Project fork' do
    it 'can submit merge requests to upstream master' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      merge_request = Factory::Resource::MergeRequestFromFork.fabricate! do |merge_request|
        merge_request.fork_branch = 'feature-branch'
      end

      Page::Menu::Main.perform { |main| main.sign_out }
      Page::Main::Login.perform { |login| login.sign_in_using_credentials }

      merge_request.visit!

      Page::MergeRequest::Show.perform { |show| show.merge! }

      expect(page).to have_content('The changes were merged')
    end
  end
end
