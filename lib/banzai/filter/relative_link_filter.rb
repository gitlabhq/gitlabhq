require 'uri'

module Banzai
  module Filter
    # HTML filter that "fixes" relative links to uploads or files in a repository.
    #
    # Context options:
    #   :commit
    #   :group
    #   :project
    #   :project_wiki
    #   :ref
    #   :requested_path
    class RelativeLinkFilter < HTML::Pipeline::Filter
      include Gitlab::Utils::StrongMemoize

      def call
        @uri_types = {}
        clear_memoization(:linkable_files)

        doc.search('a:not(.gfm)').each do |el|
          process_link_attr el.attribute('href')
        end

        doc.css('img, video').each do |el|
          process_link_attr el.attribute('src')
          process_link_attr el.attribute('data-src')
        end

        doc
      end

      protected

      def linkable_files?
        strong_memoize(:linkable_files) do
          context[:project_wiki].nil? && repository.try(:exists?) && !repository.empty?
        end
      end

      def process_link_attr(html_attr)
        return if html_attr.blank?
        return if html_attr.value.start_with?('//')

        if html_attr.value.start_with?('/uploads/')
          process_link_to_upload_attr(html_attr)
        elsif linkable_files?
          process_link_to_repository_attr(html_attr)
        end
      end

      def process_link_to_upload_attr(html_attr)
        path_parts = [Addressable::URI.unescape(html_attr.value)]

        if group
          path_parts.unshift(relative_url_root, 'groups', group.full_path, '-')
        elsif project
          path_parts.unshift(relative_url_root, project.full_path)
        end

        path = Addressable::URI.escape(File.join(*path_parts))

        html_attr.value =
          if context[:only_path]
            path
          else
            Addressable::URI.join(Gitlab.config.gitlab.base_url, path).to_s
          end
      end

      def process_link_to_repository_attr(html_attr)
        uri = URI(html_attr.value)
        if uri.relative? && uri.path.present?
          html_attr.value = rebuild_relative_uri(uri).to_s
        end
      rescue URI::Error, Addressable::URI::InvalidURIError
        # noop
      end

      def rebuild_relative_uri(uri)
        file_path = relative_file_path(uri)

        uri.path = [
          relative_url_root,
          project.full_path,
          uri_type(file_path),
          Addressable::URI.escape(ref).gsub('#', '%23'),
          Addressable::URI.escape(file_path)
        ].compact.join('/').squeeze('/').chomp('/')

        uri
      end

      def relative_file_path(uri)
        path = Addressable::URI.unescape(uri.path)
        request_path = Addressable::URI.unescape(context[:requested_path])
        nested_path = build_relative_path(path, request_path)
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
        return path[1..-1] if path.start_with?('/')

        parts = request_path.split('/')
        parts.pop if uri_type(request_path) != :tree

        path.sub!(%r{\A\./}, '')

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
        @uri_types[path] ||= current_commit.uri_type(path)
      end

      def current_commit
        @current_commit ||= context[:commit] || repository.commit(ref)
      end

      def relative_url_root
        Gitlab.config.gitlab.relative_url_root.presence || '/'
      end

      def ref
        context[:ref] || project.default_branch
      end

      def group
        context[:group]
      end

      def project
        context[:project]
      end

      def repository
        @repository ||= project&.repository
      end
    end
  end
end
