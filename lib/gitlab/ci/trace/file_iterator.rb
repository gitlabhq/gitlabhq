module Gitlab
  module Ci
    class Trace
      class FileIterator
        attr_reader :relative_path

        def initialize(relative_path)
          @relative_path = relative_path
        end

        def trace_files
          Dir.chdir(Settings.gitlab_ci.builds_path) do
            unless Dir.exist?(relative_path)
              return yield relative_path
            end

            recursive(relative_path) do |path|
              yield sanitized_path(path)
            end
          end
        end

        private

        def recursive(pos, &block)
          Dir.entries(pos).each do |entry|
            if yyyy_mm?(entry) || project_id?(entry)
              recursive(File.join(pos, entry), &block)
            elsif trace_file?(entry)
              yield File.join(pos, entry)
            end
          end
        end

        def yyyy_mm?(entry)
          /^\d{4}_\d{2}$/ =~ entry
        end

        def project_id?(entry)
          /^\d{1,}$/ =~ entry
        end

        def trace_file?(entry)
          /^\d{1,}.log$/ =~ entry
        end

        def sanitized_path(path)
          path.sub(/^\./, '').sub(%{^/}, '')
        end
      end
    end
  end
end
