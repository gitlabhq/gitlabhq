module Gitlab
  module Template
    class BaseTemplate
      def initialize(path)
        @path = path
      end

      def name
        File.basename(@path, self.class.extension)
      end

      def content
        File.read(@path)
      end

      class << self
        def all
          self.category_directories.flat_map do |dir|
            templates_for_folder(dir)
          end
        end

        def find(key)
          file_name = "#{key}#{self.extension}"

          directory = select_directory(file_name)
          directory ? new(File.join(directory, file_name)) : nil
        end

        def by_category(category)
          templates_for_folder(categories[category])
        end

        def category_directories
          self.categories.values.map { |subdir| File.join(base_dir, subdir)}
        end

        private

        def select_directory(file_name)
          category_directories.find { |dir| File.exist?(File.join(dir, file_name)) }
        end

        def templates_for_folder(dir)
          Dir.glob("#{dir.to_s}/*#{self.extension}").select { |f| f =~ filter_regex }.map { |f| new(f) }
        end

        def filter_regex
          /#{Regexp.escape(extension)}\z/
        end
      end
    end
  end
end
