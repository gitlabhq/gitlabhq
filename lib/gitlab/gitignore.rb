module Gitlab
  class Gitignore
    FILTER_REGEX = /\.gitignore\z/.freeze

    def initialize(path)
      @path = path
    end

    def name
      File.basename(@path, '.gitignore')
    end

    def content
      File.read(@path)
    end

    class << self
      def all
        languages_frameworks + global
      end

      def find(key)
        file_name = "#{key}.gitignore"

        directory = select_directory(file_name)
        directory ? new(File.join(directory, file_name)) : nil
      end

      def global
        files_for_folder(global_dir).map { |file| new(File.join(global_dir, file)) }
      end

      def languages_frameworks
        files_for_folder(gitignore_dir).map { |file| new(File.join(gitignore_dir, file)) }
      end

      private

      def select_directory(file_name)
        [gitignore_dir, global_dir].find { |dir| File.exist?(File.join(dir, file_name)) }
      end

      def global_dir
        File.join(gitignore_dir, 'Global')
      end

      def gitignore_dir
        Rails.root.join('vendor/gitignore')
      end

      def files_for_folder(dir)
        Dir.glob("#{dir.to_s}/*.gitignore").map { |file| file.gsub(FILTER_REGEX, '') }
      end
    end
  end
end
