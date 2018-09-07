module Gitlab
  module Ci
    module External
      class Mapper
        def initialize(values, project, branch_name)
          @paths = Array(values.fetch(:include, []))
          @project = project
          @branch_name = branch_name
        end

        def process
          paths.map { |path| build_external_file(path) }
        end

        private

        attr_reader :paths, :project, :branch_name

        def build_external_file(path)
          remote_file = Gitlab::Ci::External::File::Remote.new(path)

          if remote_file.valid?
            remote_file
          else
            ::Gitlab::Ci::External::File::Local.new(path, project, branch_name)
          end
        end
      end
    end
  end
end
