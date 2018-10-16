require 'securerandom'

module QA
  module Factory
    module Resource
      class Label < Factory::Base
        attr_accessor :title,
                      :description,
                      :color

        product(:title) { |factory| factory.title }

        dependency Factory::Resource::Project, as: :project do |project|
          project.name = 'project-with-label'
        end

        def initialize
          @title = "qa-test-#{SecureRandom.hex(8)}"
          @description = 'This is a test label'
          @color = '#0033CC'
        end

        def fabricate!
          project.visit!

          Page::Project::Menu.act { go_to_labels }
          Page::Label::Index.act { go_to_new_label }

          Page::Label::New.perform do |page|
            page.fill_title(@title)
            page.fill_description(@description)
            page.fill_color(@color)
            page.create_label
          end
        end
      end
    end
  end
end
