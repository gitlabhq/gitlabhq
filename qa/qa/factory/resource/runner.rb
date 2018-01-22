require 'securerandom'

module QA
  module Factory
    module Resource
      class Runner < Factory::Base
        attr_writer :name

        dependency Factory::Resource::Project, as: :project do |project|
          project.name = 'project-with-ci-cd'
          project.description = 'Project with CI/CD Pipelines'
        end

        def name
          @name || "qa-runner-#{SecureRandom.hex(4)}"
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
                runner.tags = %w[qa test]
                runner.register!
                # TODO, wait for runner to register using non-blocking method.
                sleep 5
              end
            end
          end
        end
      end
    end
  end
end
