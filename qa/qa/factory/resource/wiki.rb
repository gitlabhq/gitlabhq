module QA
  module Factory
    module Resource
      class Wiki < Factory::Base
        attr_accessor :title, :content, :message

        attribute :project do
          Factory::Resource::Project.fabricate! do |resource|
            resource.name = 'project-for-wikis'
            resource.description = 'project for adding wikis'
          end
        end

        def fabricate!
          project

          Page::Project::Menu.act { click_wiki }
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
