# frozen_string_literal: true

require 'uri'

module Banzai
  module Filter
    # HTML filter that "fixes" relative links to files in a repository.
    #
    # Context options:
    #   :commit
    #   :current_user
    #   :project
    #   :wiki
    #   :ref
    #   :requested_path
    #   :system_note
    class RepositoryLinkFilter < BaseRelativeLinkFilter
      prepend Concerns::PipelineTimingCheck

      def call
        return doc if context[:system_note]

        clear_memoization(:linkable_files)
        clear_memoization(:linkable_attributes)

        load_uri_types

        linkable_attributes.each do |attr|
          if linkable_files? && repo_visible_to_user?
            process_link_to_repository_attr(attr)
          end
        end

        doc
      end

      protected

      def load_uri_types
        return unless linkable_attributes.present?
        return unless linkable_files?
        return {} unless repository

        @uri_types = request_path.present? ? get_uri_types([request_path]) : {}

        paths = linkable_attributes.flat_map do |attr|
          [get_uri(attr).to_s, relative_file_path(get_uri(attr))]
        end

        paths.reject!(&:blank?)
        paths.uniq!

        @uri_types.merge!(get_uri_types(paths))
      end

      def linkable_files?
        strong_memoize(:linkable_files) do
          context[:wiki].nil? && repository.try(:exists?) && !repository.empty?
        end
      end

      def get_uri_types(paths)
        return {} if paths.empty?

        uri_types = paths.index_with { nil }

        get_blob_types(paths).each do |name, type|
          if type == :blob
            blob = ::Blob.decorate(Gitlab::Git::Blob.new(name: name), project)
            uri_types[name] = blob.image? || blob.video? || blob.audio? ? :raw : :blob
          else
            uri_types[name] = type
          end
        end

        uri_types
      end

      def get_blob_types(paths)
        revision_paths = paths.collect do |path|
          [current_commit.sha, path.chomp("/")]
        end

        Gitlab::GitalyClient::BlobService.new(repository).get_blob_types(revision_paths, 1)
      rescue GRPC::Unavailable, GRPC::DeadlineExceeded => e
        # Handle Gitaly connection issues gracefully
        Gitlab::ErrorTracking.track_exception(e, project_id: project.id)
        # Return all links as blob types
        paths.collect do |path|
          [path, :blob]
        end
      end

      def get_uri(html_attr)
        uri = Addressable::URI.parse(html_attr.value)

        uri if uri.relative? && uri.path.present?
      rescue URI::Error, Addressable::URI::InvalidURIError
      end

      def process_link_to_repository_attr(html_attr)
        uri = Addressable::URI.parse(html_attr.value)

        if uri.relative? && uri.path.present?
          html_attr.value = rebuild_relative_uri(uri).to_s
          html_attr.parent.add_class('gfm')
        end
      rescue URI::Error, Addressable::URI::InvalidURIError
        # noop
      end

      def rebuild_relative_uri(uri)
        file_path = nested_file_path_if_exists(uri)
        resource_type = uri_type(file_path)

        # Repository routes are under /-/ scope now.
        # Since we craft a path without using route helpers we must
        # ensure - is added here.
        prefix = '-' if %w[tree blob raw commits].include?(resource_type.to_s)

        uri.path = [
          relative_url_root,
          project.full_path,
          prefix,
          resource_type,
          Addressable::URI.escape(ref).gsub('#', '%23'),
          Addressable::URI.escape(file_path)
        ].compact.join('/').squeeze('/').chomp('/')

        uri
      end

      def nested_file_path_if_exists(uri)
        path = cleaned_file_path(uri)
        nested_path = relative_file_path(uri)

        path_exists?(nested_path) ? nested_path : path
      end

      def cleaned_file_path(uri)
        unescape_and_scrub_uri(uri.path).delete("\0").chomp("/")
      end

      def relative_file_path(uri)
        return if uri.nil?

        build_relative_path(cleaned_file_path(uri), request_path)
      end

      def request_path
        return unless context[:requested_path]

        unescape_and_scrub_uri(context[:requested_path]).chomp("/")
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
        return path[1..] if path.start_with?('/')

        parts = request_path.split('/')

        parts.pop if uri_type(request_path) != :tree

        path.delete_prefix!('./')

        while path.start_with?('../')
          parts.pop
          path.sub!('../', '')
        end

        parts.push(path).join('/')
      end

      def path_exists?(path)
        path.present? && @uri_types[path] != :unknown
      end

      def uri_type(path)
        @uri_types[path] == :unknown ? :blob : @uri_types[path]
      end

      def current_commit
        @current_commit ||= context[:commit] || repository.commit(ref)
      end

      def repo_visible_to_user?
        project && Ability.allowed?(current_user, :read_code, project)
      end

      def ref
        context[:ref] || project.default_branch
      end

      def current_user
        context[:current_user]
      end

      def repository
        @repository ||= project&.repository
      end
    end
  end
end
