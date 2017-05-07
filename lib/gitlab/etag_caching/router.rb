module Gitlab
  module EtagCaching
    class Router
      Route = Struct.new(:regexp, :name)
      # We enable an ETag for every request matching the regex.
      # To match a regex the path needs to match the following:
      #   - Don't contain a reserved word (expect for the words used in the
      #     regex itself)
      #   - Ending in `noteable/issue/<id>/notes` for the `issue_notes` route
      #   - Ending in `issues/id`/rendered_title` for the `issue_title` route
      USED_IN_ROUTES = %w[noteable issue notes issues rendered_title
                          commit pipelines merge_requests new].freeze
      RESERVED_WORDS = DynamicPathValidator::WILDCARD_ROUTES - USED_IN_ROUTES
      RESERVED_WORDS_REGEX = Regexp.union(*RESERVED_WORDS)
      ROUTES = [
        Gitlab::EtagCaching::Router::Route.new(
          %r(^(?!.*(#{RESERVED_WORDS_REGEX})).*/noteable/issue/\d+/notes\z),
          'issue_notes'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(^(?!.*(#{RESERVED_WORDS_REGEX})).*/issues/\d+/rendered_title\z),
          'issue_title'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(^(?!.*(#{RESERVED_WORDS_REGEX})).*/commit/\S+/pipelines\.json\z),
          'commit_pipelines'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(^(?!.*(#{RESERVED_WORDS_REGEX})).*/merge_requests/new\.json\z),
          'new_merge_request_pipelines'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(^(?!.*(#{RESERVED_WORDS_REGEX})).*/merge_requests/\d+/pipelines\.json\z),
          'merge_request_pipelines'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(^(?!.*(#{RESERVED_WORDS_REGEX})).*/pipelines\.json\z),
          'project_pipelines'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(^(?!.*(#{RESERVED_WORDS})).*/pipelines/\d+\.json\z),
          'project_pipeline'
        ),
      ].freeze

      def self.match(env)
        ROUTES.find { |route| route.regexp.match(env['PATH_INFO']) }
      end
    end
  end
end
