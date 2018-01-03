# Searches and reads files present on each Gitlab project repository
module Gitlab
  module Template
    module Finders
      class RepoTemplateFinder < BaseTemplateFinder
        # Raised when file is not found
        FileNotFoundError = Class.new(StandardError)

        def initialize(project, base_dir, extension, categories = {})
          @categories     = categories
          @extension      = extension
          @repository     = project.repository
          @commit         = @repository.head_commit if @repository.exists?

          super(base_dir)
        end

        def read(path)
          blob = @repository.blob_at(@commit.id, path) if @commit
          raise FileNotFoundError if blob.nil?

          blob.data
        end

        def find(key)
          file_name = "#{key}#{@extension}"
          directory = select_directory(file_name)
          raise FileNotFoundError if directory.nil?

          category_directory(directory) + file_name
        end

        def list_files_for(dir)
          return [] unless @commit

          dir << '/' unless dir.end_with?('/')

          entries = @repository.tree(:head, dir).entries

          names = entries.map(&:name)
          names.select { |f| f =~ self.class.filter_regex(@extension) }
        end

        private

        def select_directory(file_name)
          return [] unless @commit

          # Insert root as directory
          directories = ["", @categories.keys]

          directories.find do |category|
            path = category_directory(category) + file_name
            @repository.blob_at(@commit.id, path)
          end
        end
      end
    end
  end
end
