# frozen_string_literal: true

module Gitlab
  module Jira
    module Dvcs
      ENCODED_SLASH = '@'
      SLASH = '/'
      ENCODED_ROUTE_REGEX = /[a-zA-Z0-9_\-\.#{ENCODED_SLASH}]+/

      def self.encode_slash(path)
        path.gsub(SLASH, ENCODED_SLASH)
      end

      def self.decode_slash(path)
        path.gsub(ENCODED_SLASH, SLASH)
      end

      # To present two types of projects stored by Jira,
      # Type 1 are projects imported prior to nested group support,
      # those project names are not full_path, so they are presented differently
      # to maintain backwards compatibility.
      # Type 2 are projects imported after nested group support,
      # those project names are encoded full path
      #
      # @param [Project] project
      def self.encode_project_name(project)
        if project.namespace.has_parent?
          encode_slash(project.full_path)
        else
          project.path
        end
      end

      # To interpret two types of project names stored by Jira (see `encode_project_name`)
      #
      # @param [String] project
      #  Either an encoded full path, or just project name
      # @param [String] namespace
      def self.restore_full_path(namespace:, project:)
        if project.include?(ENCODED_SLASH)
          # Replace multiple slashes with single ones to make sure the redirect stays on the same host
          # full_path should not start with a `/`
          project.gsub(ENCODED_SLASH, SLASH).gsub(%r{\/{2,}}, '/').gsub(%r{^\/}, '')
        else
          "#{namespace}/#{project}"
        end
      end
    end
  end
end
