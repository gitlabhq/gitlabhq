module Gitlab
  module Ci
    module External
      class Mapper
        def initialize(values, project, sha)
          @locations = Array(values.fetch(:include, []))
          @project = project
          @sha = sha
        end

        def process
          locations.map { |location| build_external_file(location) }
        end

        private

        attr_reader :locations, :project, :sha

        def build_external_file(location)
          remote_file = Gitlab::Ci::External::File::Remote.new(location)

          if remote_file.valid?
            remote_file
          else
            options = { project: project, sha: sha }
            Gitlab::Ci::External::File::Local.new(location, options)
          end
        end
      end
    end
  end
end
