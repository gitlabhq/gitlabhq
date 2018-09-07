module Gitlab
  module Ci
    module ExternalFiles
      class Mapper
        def self.fetch_paths(values)
          paths = values.fetch(:includes, [])
          normalize_paths(paths)
        end

        def self.normalize_paths(paths)
          if paths.is_a?(String)
            [build_external_file(paths)]
          else
            paths.map { |path| build_external_file(path) }
          end
        end

        def self.build_external_file(path)
          ::Gitlab::Ci::ExternalFiles::ExternalFile.new(path)
        end
      end
    end
  end
end
