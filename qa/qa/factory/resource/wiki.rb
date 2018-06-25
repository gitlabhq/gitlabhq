module QA
  module Factory
    module Resource
      class Wiki < Factory::Base
        attr_accessor :title, :content, :message

        dependency Factory::Resource::Project, as: :project do |project|
          project.name = 'project-for-wikis'
          project.description = 'project for adding wikis'
        end

        def fabricate!
          Page::Menu::Side.act { click_wiki }
          Page::Project::Wiki::New.perform do |page|
            page.go_to_create_first_page
            page.set_title(@title)
            page.set_content(@content)
            page.set_message(@message)
            page.create_new_page
          end
        end
      end
    end
  end
end
