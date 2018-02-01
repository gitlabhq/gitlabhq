module QA
  module Factory
    module Resource
      class Issue < Factory::Base
        attr_writer :title, :description, :project

        dependency Factory::Resource::Project, as: :project do |project|
          project.name = 'project-for-issues'
          project.description = 'project for adding issues'
        end

        product :title do
          Page::Project::Issue::Show.act { issue_title }
        end

        def fabricate!
          project.visit!

          Page::Project::Show.act do
            go_to_new_issue
          end

          Page::Project::Issue::New.perform do |page|
            page.add_title(@title)
            page.add_description(@description)
            page.create_new_issue
          end
        end
      end
    end
  end
end
