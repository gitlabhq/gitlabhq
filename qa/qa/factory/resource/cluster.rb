require 'securerandom'

module QA
  module Factory
    module Resource
      class Cluster < Factory::Base

        dependency Factory::Resource::Project, as: :project

        def fabricate!
          project.visit!

          Page::Menu::Side.act { click_ci_cd_kubernetes }

          Page::Project::Clusters::Index.act { go_to_new_cluster }

          Page::Project::Clusters::New.act { add_an_existing_cluster }
        end
      end
    end
  end
end
