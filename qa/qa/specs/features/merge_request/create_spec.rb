module QA
  describe 'creates a merge request with milestone' do
    it 'user creates a new merge request'  do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      current_project = Factory::Resource::Project.fabricate! do |project|
        project.name = 'project-with-merge-request-and-milestone'
      end

      current_milestone = Factory::Resource::ProjectMilestone.fabricate! do |milestone|
        milestone.title = 'unique-milestone'
        milestone.project = current_project
      end

      Factory::Resource::MergeRequest.fabricate! do |merge_request|
        merge_request.title = 'This is a merge request with a milestone'
        merge_request.description = 'Great feature with milestone'
        merge_request.project = current_project
        merge_request.milestone = current_milestone
      end

      expect(page).to have_content('This is a merge request with a milestone')
      expect(page).to have_content('Great feature with milestone')
      expect(page).to have_content(/Opened [\w\s]+ ago/)

      Page::Issuable::Sidebar.perform do |sidebar|
        expect(sidebar).to have_milestone(current_milestone.title)
      end
    end
  end

  describe 'creates a merge request', :smoke do
    it 'user creates a new merge request'  do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      current_project = Factory::Resource::Project.fabricate! do |project|
        project.name = 'project-with-merge-request'
      end

      Factory::Resource::MergeRequest.fabricate! do |merge_request|
        merge_request.title = 'This is a merge request'
        merge_request.description = 'Great feature'
        merge_request.project = current_project
      end

      expect(page).to have_content('This is a merge request')
      expect(page).to have_content('Great feature')
      expect(page).to have_content(/Opened [\w\s]+ ago/)
    end
  end
end
