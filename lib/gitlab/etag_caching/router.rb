module Gitlab
  module EtagCaching
    class Router
      Route = Struct.new(:regexp, :name)
      # We enable an ETag for every request matching the regex.
      # To match a regex the path needs to match the following:
      #   - Don't contain a reserved word (expect for the words used in the
      #     regex itself)
      #   - Ending in `noteable/issue/<id>/notes` for the `issue_notes` route
<<<<<<< HEAD
      #   - Ending in `issues/id`/rendered_title` for the `issue_title` route
<<<<<<< HEAD
=======
      #   - Ending in `issues/id`/realtime_changes` for the `issue_title` route
>>>>>>> 2f62af6... Restore original comment [ci skip]
      USED_IN_ROUTES = %w[noteable issue notes issues realtime_changes
<<<<<<< HEAD
<<<<<<< HEAD
                          commit pipelines merge_requests new].freeze
=======
                          commit pipelines merge_requests builds
                          new].freeze

>>>>>>> 47a0276... Initial implementation for real time job view
      RESERVED_WORDS = Gitlab::PathRegex::ILLEGAL_PROJECT_PATH_WORDS - USED_IN_ROUTES
      RESERVED_WORDS_REGEX = Regexp.union(*RESERVED_WORDS.map(&Regexp.method(:escape)))
=======
=======
      USED_IN_ROUTES = %w[noteable issue notes issues rendered_title
>>>>>>> 4535d52... Use etag caching for environments JSON
                          commit pipelines merge_requests new
                          environments].freeze
      RESERVED_WORDS = DynamicPathValidator::WILDCARD_ROUTES - USED_IN_ROUTES
      RESERVED_WORDS_REGEX = Regexp.union(*RESERVED_WORDS)
>>>>>>> ebede2b... Use etag caching for environments JSON
      ROUTES = [
        Gitlab::EtagCaching::Router::Route.new(
          %r(^(?!.*(#{RESERVED_WORDS_REGEX})).*/noteable/issue/\d+/notes\z),
          'issue_notes'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(^(?!.*(#{RESERVED_WORDS_REGEX})).*/issues/\d+/realtime_changes\z),
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
          %r(^(?!.*(#{RESERVED_WORDS_REGEX})).*/pipelines/\d+\.json\z),
          'project_pipeline'
        ),
        Gitlab::EtagCaching::Router::Route.new(
<<<<<<< HEAD
<<<<<<< HEAD
          %r(^(?!.*(#{RESERVED_WORDS_REGEX})).*/environments\.json\z),
=======
          %r(^(?!.*(#{RESERVED_WORDS})).*/environments\.json\z),
>>>>>>> 4535d52... Use etag caching for environments JSON
          'environments'
=======
          %r(^(?!.*(#{RESERVED_WORDS_REGEX})).*/builds/\d+\.json\z),
          'project_build'
>>>>>>> 47a0276... Initial implementation for real time job view
        )
      ].freeze

      def self.match(env)
        ROUTES.find { |route| route.regexp.match(env['PATH_INFO']) }
      end
    end
  end
end
