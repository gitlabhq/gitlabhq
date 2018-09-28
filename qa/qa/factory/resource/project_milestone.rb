module QA
  module Factory
    module Resource
      class ProjectMilestone < Factory::Base
        attr_accessor :description
        attr_reader :title

        dependency Factory::Resource::Project, as: :project

        product(:title) { |factory| factory.title }

        def title=(title)
          @title = "#{title}-#{SecureRandom.hex(4)}"
          @description = 'A milestone'
        end

        def fabricate!
          project.visit!

          Page::Menu::Side.act do
            click_issues
            click_milestones
          end

          Page::Project::Milestone::Index.act { click_new_milestone }

          Page::Project::Milestone::New.perform do |milestone_new|
            milestone_new.set_title(@title)
            milestone_new.set_description(@description)
            milestone_new.create_new_milestone
          end
        end
      end
    end
  end
end
