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
          self.categories.keys.flat_map { |cat| by_category(cat) }
        end

        def find(key)
          file_name = "#{key}#{self.extension}"

          directory = select_directory(file_name)
          directory ? new(File.join(category_directory(directory), file_name)) : nil
        end

        def categories
          raise NotImplementedError
        end

        def extension
          raise NotImplementedError
        end

        def base_dir
          raise NotImplementedError
        end

        def by_category(category)
          templates_for_directory(category_directory(category))
        end

        def category_directory(category)
          File.join(base_dir, categories[category])
        end

        private

        def select_directory(file_name)
          categories.keys.find do |category|
            File.exist?(File.join(category_directory(category), file_name))
          end
        end

        def templates_for_directory(dir)
          dir << '/' unless dir.end_with?('/')
          Dir.glob(File.join(dir, "*#{self.extension}")).select { |f| f =~ filter_regex }.map { |f| new(f) }
        end

        def filter_regex
          @filter_reges ||= /#{Regexp.escape(extension)}\z/
        end
      end
    end
  end
end
