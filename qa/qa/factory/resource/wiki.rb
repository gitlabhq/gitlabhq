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
          project.visit!

          Page::Project::Menu.perform { |menu_side| menu_side.click_wiki }

          Page::Project::Wiki::New.perform do |wiki_new|
            wiki_new.go_to_create_first_page
            wiki_new.set_title(@title)
            wiki_new.set_content(@content)
            wiki_new.set_message(@message)
            wiki_new.create_new_page
          end
        end
      end
    end
  end
end
