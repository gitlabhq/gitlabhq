module Gitlab
  module Template
    class BaseTemplate
      def initialize(path, project = nil)
        @path = path
        @finder = self.class.finder(project)
      end

      def name
        File.basename(@path, self.class.extension)
      end

      def content
        @finder.read(@path)
      end

      def to_json
        { name: name, content: content }
      end

      def <=>(other)
        name <=> other.name
      end

      class << self
        def all(project = nil)
          if categories.any?
            categories.keys.flat_map { |cat| by_category(cat, project) }
          else
            by_category("", project)
          end
        end

        def find(key, project = nil)
          path = self.finder(project).find(key)
          path.present? ? new(path, project) : nil
        end

        # Set categories as sub directories
        # Example: { "category_name_1" => "directory_path_1", "category_name_2" => "directory_name_2" }
        # Default is no category with all files in base dir of each class
        def categories
          {}
        end

        def extension
          raise NotImplementedError
        end

        def base_dir
          raise NotImplementedError
        end

        # Defines which strategy will be used to get templates files
        # RepoTemplateFinder - Finds templates on project repository, templates are filtered perproject
        # GlobalTemplateFinder - Finds templates on gitlab installation source, templates can be used in all projects
        def finder(project = nil)
          raise NotImplementedError
        end

        def by_category(category, project = nil)
          directory = category_directory(category)
          files = finder(project).list_files_for(directory)

          files.map { |f| new(f, project) }.sort
        end

        def category_directory(category)
          return base_dir unless category.present?

          File.join(base_dir, categories[category])
        end

        # If template is organized by category it returns { category_name: [{ name: template_name }, { name: template2_name }] }
        # If no category is present returns [{ name: template_name }, { name: template2_name}]
        def dropdown_names(project = nil)
          return [] if project && !project.repository.exists?

          if categories.any?
            categories.keys.map do |category|
              files = self.by_category(category, project)
              [category, files.map { |t| { name: t.name } }]
            end.to_h
          else
            files = self.all(project)
            files.map { |t| { name: t.name } }
          end
        end
      end
    end
  end
end
