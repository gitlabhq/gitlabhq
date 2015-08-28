module Composer
  module Package
    module Loader
      # Loads a package from existing configuration
      class ProjectLoader

        def initialize(loader = nil)
          if loader.nil?
            loader = Composer::Package::Loader::HashLoader.new
          end
          @loader = loader
        end

        # Load a project ref as a package
        # Param:  Project project The target gitlab project.
        # Param:  Branch|Tag ref The target gitlab project branch/tag.
        # Param:  Hash config A hash containing addional package configuration.
        # Returns: Composer::Package::Package
        def load(project, ref, config)

          config['version'] = parse_version(ref)

          # export distribution package
          # this works only on public repositories since composer can't handle gitlab oAuth yet.
          if project.public?
            config['dist'] = {
              'url' => Rails.application.routes.url_helpers.archive_namespace_project_repository_url(project.namespace, project, ref: ref.name, format: 'zip'),
              'type' => 'zip',
              'reference' => ref.target
            }
          end

          # export source package
          config['source'] = {
            'url' => project.url_to_repo,
            'type' => 'git',
            'reference' => ref.target
          }

          @loader.load(config)
        end

        private

        def parse_version(ref)
          ref.instance_of?(Gitlab::Git::Branch) ? "dev-#{ref.name}" : ref.name
        end

      end
    end
  end
end
