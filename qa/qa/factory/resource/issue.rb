module QA
  module Factory
    module Resource
      class Issue < Factory::Base
        attr_writer :description

        attribute :project do
          Factory::Resource::Project.fabricate! do |resource|
            resource.name = 'project-for-issues'
            resource.description = 'project for adding issues'
          end
        end

        attribute :title do
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
