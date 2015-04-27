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
        # Param:  string|JsonFile json A filename, json string or JsonFile instance to load the package from
        # Returns: Composer::Package::Package
        def load(project, ref, config)

          config['version'] = parse_version(ref)

          # export distribution package
          # this works only on public repositories since composer can't handle gitlab oAuth yet.
          if project.public?
            config['dist'] = {
              'url'  => [project.web_url, 'repository', 'archive.zip?ref=' + ref.name].join('/'),
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
