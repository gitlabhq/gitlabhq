module QA
  module Factory
    module Resource
      class Wiki < Factory::Resource::Project
        attr_accessor :title, :content, :message

        dependency Factory::Resource::Group, as: :group

        def initialize
          @name = 'project-for-wikis'
          @description = 'project for adding wikis'
        end

        def fabricate!
          super
          Page::Menu::Side.act { click_wiki }
          Page::Project::Wiki::Empty.act { create_wiki }
          Page::Project::Wiki::Form.perform do |page|
            page.add_title(@title)
            page.add_content(@content)
            page.add_message(@message)
            page.create_new_page
          end
        end
      end
    end
  end
end
