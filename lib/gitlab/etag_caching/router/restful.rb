# frozen_string_literal: true

module Gitlab
  module EtagCaching
    module Router
      class Restful
        extend EtagCaching::Router::Helpers

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
          [
            %r(#{RESERVED_WORDS_PREFIX}/noteable/issue/\d+/notes\z),
            'issue_notes',
            'issue_tracking'
          ],
          [
            %r(#{RESERVED_WORDS_PREFIX}/noteable/merge_request/\d+/notes\z),
            'merge_request_notes',
            'code_review'
          ],
          [
            %r(#{RESERVED_WORDS_PREFIX}/issues/\d+/realtime_changes\z),
            'issue_title',
            'issue_tracking'
          ],
          [
            %r(#{RESERVED_WORDS_PREFIX}/commit/\S+/pipelines\.json\z),
            'commit_pipelines',
            'continuous_integration'
          ],
          [
            %r(#{RESERVED_WORDS_PREFIX}/merge_requests/new\.json\z),
            'new_merge_request_pipelines',
            'continuous_integration'
          ],
          [
            %r(#{RESERVED_WORDS_PREFIX}/merge_requests/\d+/pipelines\.json\z),
            'merge_request_pipelines',
            'continuous_integration'
          ],
          [
            %r(#{RESERVED_WORDS_PREFIX}/pipelines\.json\z),
            'project_pipelines',
            'continuous_integration'
          ],
          [
            %r(#{RESERVED_WORDS_PREFIX}/pipelines/\d+\.json\z),
            'project_pipeline',
            'continuous_integration'
          ],
          [
            %r(#{RESERVED_WORDS_PREFIX}/builds/\d+\.json\z),
            'project_build',
            'continuous_integration'
          ],
          [
            %r(#{RESERVED_WORDS_PREFIX}/clusters/\d+/environments\z),
            'cluster_environments',
            'continuous_delivery'
          ],
          [
            %r(#{RESERVED_WORDS_PREFIX}/environments\.json\z),
            'environments',
            'continuous_delivery'
          ],
          [
            %r(#{RESERVED_WORDS_PREFIX}/import/github/realtime_changes\.json\z),
            'realtime_changes_import_github',
            'importers'
          ],
          [
            %r(#{RESERVED_WORDS_PREFIX}/import/gitea/realtime_changes\.json\z),
            'realtime_changes_import_gitea',
            'importers'
          ],
          [
            %r(#{RESERVED_WORDS_PREFIX}/merge_requests/\d+/cached_widget\.json\z),
            'merge_request_widget',
            'code_review'
          ]
        ].map(&method(:build_route)).freeze

        # Overridden in EE to add more routes
        def self.all_routes
          ROUTES
        end

        def self.match(request)
          all_routes.find { |route| route.match(request.path_info) }
        end

        def self.cache_key(request)
          request.path
        end
      end
    end
  end
end

Gitlab::EtagCaching::Router::Restful.prepend_mod_with('Gitlab::EtagCaching::Router::Restful')
