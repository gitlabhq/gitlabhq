# frozen_string_literal: true

# Searches and reads file present on GitLab installation directory
module Gitlab
  module Template
    module Finders
      class GlobalTemplateFinder < BaseTemplateFinder
        def initialize(base_dir, extension, categories = {}, excluded_patterns: [])
          @categories = categories
          @extension  = extension
          @excluded_patterns = excluded_patterns

          super(base_dir)
        end

        def read(path)
          File.read(path)
        end

        def find(key)
          return if excluded?(key)

          file_name = "#{key}#{@extension}"

          # The key is untrusted input, so ensure we can't be directed outside
          # of base_dir
          Gitlab::Utils.check_path_traversal!(file_name)

          directory = select_directory(file_name)
          directory ? File.join(category_directory(directory), file_name) : nil
        end

        def list_files_for(dir)
          dir = "#{dir}/" unless dir.end_with?('/')

          Dir.glob(File.join(dir, "*#{@extension}")).select do |f|
            next if excluded?(f)

            f =~ self.class.filter_regex(@extension)
          end
        end

        private

        def excluded?(file_name)
          @excluded_patterns.any? { |pattern| pattern.match?(file_name) }
        end

        def select_directory(file_name)
          @categories.keys.find do |category|
            File.exist?(File.join(category_directory(category), file_name))
          end
        end
      end
    end
  end
end
