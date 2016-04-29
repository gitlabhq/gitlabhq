module Gitlab
  class Gitignore
    FILTER_REGEX = /\.gitignore\z/.freeze

    attr_accessor :name, :directory

    def initialize(name, directory)
      @name       = name
      @directory  = directory
    end

    def content
      File.read(path)
    end

    class << self
      def all
        languages_frameworks + global
      end

      def find(key)
        file_name = "#{key}.gitignore"

        directory = select_directory(file_name)
        directory ? new(key, directory) : nil
      end

      def global
        files_for_folder(global_dir).map { |f| new(f, global_dir) }
      end

      def languages_frameworks
        files_for_folder(gitignore_dir).map { |f| new(f, gitignore_dir) }
      end
    end

    private

    def path
      File.expand_path("#{name}.gitignore", directory)
    end

    class << self
      def select_directory(file_name)
        [self.gitignore_dir, self.global_dir].find { |dir| File.exist?(File.expand_path(file_name, dir)) }
      end

      def global_dir
        File.expand_path('Global', gitignore_dir)
      end

      def gitignore_dir
        File.expand_path('vendor/gitignore', Rails.root)
      end

      def files_for_folder(dir)
        gitignores = []
        Dir.entries(dir).each do |e|
          next unless e.end_with?('.gitignore')

          gitignores << e.gsub(FILTER_REGEX, '')
        end

        gitignores
      end
    end
  end
end
