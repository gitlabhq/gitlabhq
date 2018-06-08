module QA
  feature 'Wiki Functionality', :core do
    def login
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }
    end

    def validate_content(content)
      expect(page).to have_content('Wiki was successfully updated')
      expect(page).to have_content(/#{content}/)
    end

    before(:all) do
      login
    end

    scenario 'User creates a page in wiki for a project' do
      @wiki = Factory::Resource::Wiki.fabricate! do |resource|
        resource.title = 'Home'
        resource.content = '# My First Wiki Content'
        resource.message = 'Update home'
      end
      validate_content('My First Wiki Content')

      Page::Project::Wiki::MainLinks.act { edit_page }
      Page::Project::Wiki::Edit.perform do |page|
        page.add_content("My Second Wiki Content")
        page.save_changes
      end
      validate_content('My Second Wiki Content')

      Page::Project::Wiki::Pages.act { clone_repository }
      Factory::Repository::Push.fabricate! do |resource|
        resource.project = @wiki
        resource.file_name = 'Home.md'
        resource.commit_message = 'Updating Home Page'
        resource.file_content = '# My Third Wiki Content'
        resource.new_branch = false
      end

      Page::Menu::Side.act { click_wiki }
      expect(page).to have_content('My Third Wiki Content')
    end
  end
end
