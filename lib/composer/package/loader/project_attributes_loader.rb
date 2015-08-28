module Composer
  module Package
    module Loader
      # Loads a package from the project attributes
      class ProjectAttributesLoader < Composer::Package::Loader::ProjectLoader

        def initialize(loader = nil)
          if loader.nil?
            loader = Composer::Package::Loader::HashLoader.new
          end
          @loader = loader
        end

        # Load a json string or file
        # Param:  Project project The target gitlab project.
        # Param:  Branch|Tag ref The target gitlab project branch/tag.
        # Param:  Hash config A hash containing addional package configuration.
        # Returns: Composer::Package::Package
        def load(project, ref, type = 'library')
          config = {
            'name'                => project.path_with_namespace.downcase,
            'description'         => project.description || '',
            'type'                => type,
            'homepage'            => project.web_url
          }

          if time = parse_time(project, ref)
            config['time'] = time
          end

          if keywords = parse_keywords(project)
            config['keywords'] = keywords
          end

          super(project, ref, config)
        end

        private

        def parse_time(project, ref)
          commit = project.repository.commit(ref.target)
          commit.committed_date.strftime('%Y-%m-%d %H:%M:%S')
        rescue
          # If there's a problem, just skip the "time" field
        end

        def parse_keywords(project)
          project.tags.collect { |t| t['name'] }
        rescue
          # If there's a problem, just skip the "keyworks"
        end

      end
    end
  end
end
