module QA
  feature 'creates a merge request', :core do
    scenario 'user creates a new merge request'  do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      Factory::Resource::MergeRequest.fabricate! do |merge_request|
        merge_request.title = 'This is a merge request'
        merge_request.description = 'Great feature'
      end

      expect(page).to have_content('This is a merge request')
      expect(page).to have_content('Great feature')
      expect(page).to have_content('Opened less than a minute ago')
    end
  end
end
