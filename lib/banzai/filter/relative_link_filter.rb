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

        @uri_types = {}

        doc.search('a:not(.gfm)').each do |el|
          process_link_attr el.attribute('href')
        end

        doc.css('img, video').each do |el|
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
          uri_type(file_path),
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
        parts.pop if uri_type(request_path) != :tree

        while path.start_with?('../')
          parts.pop
          path.sub!('../', '')
        end

        parts.push(path).join('/')
      end

      def file_exists?(path)
        path.present? && !!uri_type(path)
      end

      def uri_type(path)
        @uri_types[path] ||= begin
          unescaped_path = Addressable::URI.unescape(path)

          current_commit.uri_type(unescaped_path)
        end
      end

      def current_commit
        @current_commit ||= context[:commit] ||
          ref ? repository.commit(ref) : repository.head_commit
      end

      def relative_url_root
        Gitlab.config.gitlab.relative_url_root.presence || '/'
      end

      def ref
        context[:ref]
      end

      def repository
        @repository ||= context[:project].try(:repository)
      end
    end
  end
end
