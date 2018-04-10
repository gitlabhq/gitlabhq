require 'securerandom'

module QA
  module Factory
    module Resource
      class Runner < Factory::Base
        attr_writer :name, :tags, :image

        dependency Factory::Resource::Project, as: :project do |project|
          project.name = 'project-with-ci-cd'
          project.description = 'Project with CI/CD Pipelines'
        end

        def name
          @name || "qa-runner-#{SecureRandom.hex(4)}"
        end

        def tags
          @tags || %w[qa e2e]
        end

        def image
          @image || 'gitlab/gitlab-runner:alpine'
        end

        def fabricate!
          project.visit!

          Page::Menu::Side.act { click_ci_cd_settings }

          Service::Runner.new(name).tap do |runner|
            Page::Project::Settings::CICD.perform do |settings|
              settings.expand_runners_settings do |runners|
                runner.pull
                runner.token = runners.registration_token
                runner.address = runners.coordinator_address
                runner.tags = tags
                runner.image = image
                runner.register!
              end
            end
          end
        end
      end
    end
  end
end
