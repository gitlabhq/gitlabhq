module Gitlab
  module EtagCaching
    class Router
      Route = Struct.new(:regexp, :name)

      RESERVED_WORDS = NamespaceValidator::WILDCARD_ROUTES.map { |word| "/#{word}/" }.join('|')
      ROUTES = [
        Gitlab::EtagCaching::Router::Route.new(
          %r(^(?!.*(#{RESERVED_WORDS})).*/noteable/issue/\d+/notes\z),
          'issue_notes'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(^(?!.*(#{RESERVED_WORDS})).*/issues/\d+/rendered_title\z),
          'issue_title'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(^(?!.*(#{RESERVED_WORDS})).*/commit/\S+/pipelines\.json\z),
          'commit_pipelines'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(^(?!.*(#{RESERVED_WORDS})).*/merge_requests/new\.json\z),
          'new_merge_request_pipelines'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(^(?!.*(#{RESERVED_WORDS})).*/merge_requests/\d+/pipelines\.json\z),
          'merge_request_pipelines'
        ),
        Gitlab::EtagCaching::Router::Route.new(
          %r(^(?!.*(#{RESERVED_WORDS})).*/pipelines\.json\z),
          'project_pipelines'
        )
      ].freeze

      def self.match(env)
        ROUTES.find { |route| route.regexp.match(env['PATH_INFO']) }
      end
    end
  end
end
