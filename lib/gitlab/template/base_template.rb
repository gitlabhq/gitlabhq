# frozen_string_literal: true

module Gitlab
  module Template
    class BaseTemplate
      attr_accessor :category

      def initialize(path, project = nil, category: nil)
        @path = path
        @category = category
        @project = project
        @finder = self.class.finder(project)
      end

      def name
        File.basename(@path, self.class.extension)
      end
      alias_method :key, :name

      def full_name
        Pathname.new(@path)
          .relative_path_from(self.class.base_dir)
          .to_s
      end

      def content
        blob = @finder.read(@path)
        [description, blob].compact.join("\n")
      end

      def description
        # override with a comment to be placed at the top of the blob.
      end

      def project_id
        @project&.id
      end

      # Present for compatibility with license templates, which can replace text
      # like `[fullname]` with a user-specified string. This is a no-op for
      # other templates
      def resolve!(_placeholders = {})
        self
      end

      def to_json(*)
        { key: key, name: name, content: content }
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
        # RepoTemplateFinder - Finds templates on project repository, templates are filtered per project
        # GlobalTemplateFinder - Finds templates on gitlab installation source, templates can be used in all projects
        def finder(project = nil)
          raise NotImplementedError
        end

        def by_category(category, project = nil, empty_category_title: nil)
          directory = category_directory(category)
          files = finder(project).list_files_for(directory)

          files.map { |f| new(f, project, category: category.presence || empty_category_title) }.sort
        end

        def category_directory(category)
          return base_dir unless category.present?

          File.join(base_dir, categories[category])
        end

        # `repository_template_names` - reads through Gitaly the actual templates names within a
        # given project's repository. This is only used by issue and merge request templates,
        # that need to call this once and then cache the returned value.
        #
        # `template_names` - is an alias to `repository_template_names`. It would read through
        # Gitaly the actual template names within a given project's repository for all file templates
        # other than `issue` and `merge request` description templates, which would instead
        # overwrite the `template_names` method to return a redis cached version, by reading cached values
        # from `repository.issue_template_names_hash` and `repository.merge_request_template_names_hash`
        # methods.
        def repository_template_names(project)
          template_names_by_category(self.all(project))
        end
        alias_method :template_names, :repository_template_names

        def template_names_by_category(items)
          grouped = items.group_by(&:category)
          categories = grouped.keys

          categories.each_with_object({}) do |category, hash|
            hash[category] = grouped[category].map do |item|
              { name: item.name, id: item.key, key: item.key, project_id: item.try(:project_id) }
            end
          end
        end

        def template_subsets(project = nil)
          return [] if project && !project.repository.exists?

          if categories.any?
            categories.keys.to_h do |category|
              files = self.by_category(category, project)
              [category, files.map { |t| { key: t.key, name: t.name, content: t.content } }]
            end
          else
            files = self.all(project)
            files.map { |t| { key: t.key, name: t.name, content: t.content } }
          end
        end
      end
    end
  end
end
