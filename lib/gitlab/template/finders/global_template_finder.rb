# Searches and reads file present on Gitlab installation directory
module Gitlab
  module Template
    module Finders
      class GlobalTemplateFinder < BaseTemplateFinder
        def initialize(base_dir, extension, categories = {})
          @categories = categories
          @extension  = extension
          super(base_dir)
        end

        def read(path)
          File.read(path)
        end

        def find(key)
          file_name = "#{key}#{@extension}"

          directory = select_directory(file_name)
          directory ? File.join(category_directory(directory), file_name) : nil
        end

        def list_files_for(dir)
          dir << '/' unless dir.end_with?('/')
          Dir.glob(File.join(dir, "*#{@extension}")).select { |f| f =~ self.class.filter_regex(@extension) }
        end

        private

        def select_directory(file_name)
          @categories.keys.find do |category|
            File.exist?(File.join(category_directory(category), file_name))
          end
        end
      end
    end
  end
end
