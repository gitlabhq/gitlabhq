# frozen_string_literal: true

module Gitlab
  module EtagCaching
    class Router
      Route = Struct.new(:regexp, :name)
      # We enable an ETag for every request matching the regex.
      # To match a regex the path needs to match the following:
      #   - Don't contain a reserved word (expect for the words used in the
      #     regex itself)
      #   - Ending in `noteable/issue/<id>/notes` for the `issue_notes` route
      #   - Ending in `issues/id`/realtime_changes` for the `issue_title` route
      USED_IN_ROUTES = %w[noteable issue notes issues realtime_changes
                          commit pipelines merge_requests builds
                          new environments].freeze
      RESERVED_WORDS = Gitlab::PathRegex::ILLEGAL_PROJECT_PATH_WORDS - USED_IN_ROUTES
      RESERVED_WORDS_REGEX = Regexp.union(*RESERVED_WORDS.map(&Regexp.method(:escape)))
      RESERVED_WORDS_PREFIX = %Q(^(?!.*\/(#{RESERVED_WORDS_REGEX})\/).*)

      ROUTES = [
        Gitlab::EtagCaching::Router::Route.new(
          %r(#{RESERVED_WORDS_PREFIX}/noteable/issue/\d+/notes\z),
          'issue_notes'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(#{RESERVED_WORDS_PREFIX}/noteable/merge_request/\d+/notes\z),
          'merge_request_notes'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(#{RESERVED_WORDS_PREFIX}/issues/\d+/realtime_changes\z),
          'issue_title'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(#{RESERVED_WORDS_PREFIX}/commit/\S+/pipelines\.json\z),
          'commit_pipelines'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(#{RESERVED_WORDS_PREFIX}/merge_requests/new\.json\z),
          'new_merge_request_pipelines'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(#{RESERVED_WORDS_PREFIX}/merge_requests/\d+/pipelines\.json\z),
          'merge_request_pipelines'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(#{RESERVED_WORDS_PREFIX}/pipelines\.json\z),
          'project_pipelines'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(#{RESERVED_WORDS_PREFIX}/pipelines/\d+\.json\z),
          'project_pipeline'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(#{RESERVED_WORDS_PREFIX}/builds/\d+\.json\z),
          'project_build'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(#{RESERVED_WORDS_PREFIX}/clusters/\d+/environments\z),
          'cluster_environments'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(#{RESERVED_WORDS_PREFIX}/environments\.json\z),
          'environments'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(#{RESERVED_WORDS_PREFIX}/import/github/realtime_changes\.json\z),
          'realtime_changes_import_github'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(#{RESERVED_WORDS_PREFIX}/import/gitea/realtime_changes\.json\z),
          'realtime_changes_import_gitea'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(#{RESERVED_WORDS_PREFIX}/merge_requests/\d+/cached_widget\.json\z),
          'merge_request_widget'
        )
      ].freeze

      def self.match(path)
        ROUTES.find { |route| route.regexp.match(path) }
      end
    end
  end
end

Gitlab::EtagCaching::Router.prepend_if_ee('EE::Gitlab::EtagCaching::Router')
