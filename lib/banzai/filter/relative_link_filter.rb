require 'html/pipeline/filter'
require 'uri'

module Banzai
  module Filter
    # HTML filter that "fixes" relative links to files in a repository.
    #
    # Context options:
    #   :commit
    #   :project
    #   :project_wiki
    #   :ref
    #   :requested_path
    class RelativeLinkFilter < HTML::Pipeline::Filter
      def call
        return doc unless linkable_files?

        doc.search('a:not(.gfm)').each do |el|
          process_link_attr el.attribute('href')
        end

        doc.search('img').each do |el|
          process_link_attr el.attribute('src')
        end

        doc
      end

      protected

      def linkable_files?
        context[:project_wiki].nil? && repository.try(:exists?) && !repository.empty?
      end

      def process_link_attr(html_attr)
        return if html_attr.blank?

        uri = URI(html_attr.value)
        if uri.relative? && uri.path.present?
          html_attr.value = rebuild_relative_uri(uri).to_s
        end
      rescue URI::Error
        # noop
      end

      def rebuild_relative_uri(uri)
        file_path = relative_file_path(uri.path)

        uri.path = [
          relative_url_root,
          context[:project].path_with_namespace,
          path_type(file_path),
          ref || context[:project].default_branch,  # if no ref exists, point to the default branch
          file_path
        ].compact.join('/').squeeze('/').chomp('/')

        uri
      end

      def relative_file_path(path)
        nested_path = build_relative_path(path, context[:requested_path])
        file_exists?(nested_path) ? nested_path : path
      end

      # Convert a relative path into its correct location based on the currently
      # requested path
      #
      # path         - Relative path String
      # request_path - Currently-requested path String
      #
      # Examples:
      #
      #   # File in the same directory as the current path
      #   build_relative_path("users.md", "doc/api/README.md")
      #   # => "doc/api/users.md"
      #
      #   # File in the same directory, which is also the current path
      #   build_relative_path("users.md", "doc/api")
      #   # => "doc/api/users.md"
      #
      #   # Going up one level to a different directory
      #   build_relative_path("../update/7.14-to-8.0.md", "doc/api/README.md")
      #   # => "doc/update/7.14-to-8.0.md"
      #
      # Returns a String
      def build_relative_path(path, request_path)
        return request_path if path.empty?
        return path unless request_path

        parts = request_path.split('/')
        parts.pop if path_type(request_path) != 'tree'

        while path.start_with?('../')
          parts.pop
          path.sub!('../', '')
        end

        parts.push(path).join('/')
      end

      def file_exists?(path)
        return false if path.nil?
        repository.blob_at(current_sha, path).present? ||
          repository.tree(current_sha, path).entries.any?
      end

      # Get the type of the given path
      #
      # path - String path to check
      #
      # Examples:
      #
      #   path_type('doc/README.md') # => 'blob'
      #   path_type('doc/logo.png')  # => 'raw'
      #   path_type('doc/api')       # => 'tree'
      #
      # Returns a String
      def path_type(path)
        unescaped_path = Addressable::URI.unescape(path)

        if tree?(unescaped_path)
          'tree'
        elsif image?(unescaped_path)
          'raw'
        else
          'blob'
        end
      end

      def tree?(path)
        repository.tree(current_sha, path).entries.any?
      end

      def image?(path)
        repository.blob_at(current_sha, path).try(:image?)
      end

      def current_sha
        context[:commit].try(:id) ||
          ref ? repository.commit(ref).try(:sha) : repository.head_commit.sha
      end

      def relative_url_root
        Gitlab.config.gitlab.relative_url_root.presence || '/'
      end

      def ref
        context[:ref]
      end

      def repository
        context[:project].try(:repository)
      end
    end
  end
end
