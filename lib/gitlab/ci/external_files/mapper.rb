module Gitlab
  module Ci
    module ExternalFiles
      class Mapper
        def initialize(values, project)
          @paths = values.fetch(:include, [])
          @project = project
        end

        def process
          if paths.is_a?(String)
            [build_external_file(paths)]
          else
            paths.map { |path| build_external_file(path) }
          end
        end

        private

        attr_reader :paths, :project

        def build_external_file(path)
          ::Gitlab::Ci::ExternalFiles::ExternalFile.new(path, project)
        end
      end
    end
  end
end
