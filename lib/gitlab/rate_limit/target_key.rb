# frozen_string_literal: true

module Gitlab
  module RateLimit
    # Names what the tier-aware namespace throttles should look up for a request:
    # a route path, a project id, or a group id. Returns nil when the path names no
    # namespace, as GraphQL and the top-level routes do.
    #
    # Takes a String rather than a request, so Rack::Request#params - which merges
    # the parsed body and would parse every upload - cannot be reached from here.
    module TargetKey
      ORG_SCOPE_PREFIX = '/o/'
      ORG_SCOPE_REGEX = %r{\A/o/[^/]+}
      API_PREFIX_REGEX = %r{\A/api/v\d+/(projects|groups)/([^/]+)}
      NUMERIC_ID_REGEX = /\A\d+\z/
      GIT_SUFFIX = '.git'

      class << self
        def for(path)
          return unless path.is_a?(String) && !path.empty?
          # Malformed bytes are already a 400 in Gitlab::Middleware::HandleMalformedStrings,
          # but the regexes below would raise on them, so do not rely on that alone.
          return unless path.valid_encoding?

          unscoped = strip_org_scope(strip_relative_url_root(path))

          return api_key(unscoped) if unscoped.start_with?('/api/')

          route_key(unscoped)
        end

        private

        # An instance mounted at a relative root prefixes every path with it, so that
        # segment would otherwise read as the namespace.
        def strip_relative_url_root(path)
          path.delete_prefix(::Gitlab.config.gitlab.relative_url_root)
        end

        # Every route has an organization-scoped twin under /o/:organization_path
        # (config/routes.rb), and `o` is a top-level route, so without stripping the
        # prefix every one of them would derive nothing.
        def strip_org_scope(path)
          return path unless path.start_with?(ORG_SCOPE_PREFIX)

          path.sub(ORG_SCOPE_REGEX, '')
        end

        # Only /projects/:id and /groups/:id name a target in the path. Everything
        # else, GraphQL included, carries it in the body or not at all.
        def api_key(path)
          match = API_PREFIX_REGEX.match(path)
          return unless match

          identifier_key(match[1], match[2])
        end

        def identifier_key(collection, raw_id)
          kind = collection == 'projects' ? 'project' : 'group'
          return "#{kind}:#{raw_id}" if NUMERIC_ID_REGEX.match?(raw_id)

          # A path id arrives percent-encoded and stays that way: Grape decodes it
          # downstream of this middleware, and nothing upstream does.
          decoded = Rack::Utils.unescape_path(raw_id)

          return unless decoded.valid_encoding?

          route_target(decoded.split('/'))
        end

        def route_target(segments)
          return if segments.empty? || segments.length > max_route_segments

          "route:#{segments.join('/').downcase}"
        end

        def route_key(path)
          segments = path.delete_prefix('/').split('/')
          return if segments.empty? || top_level_routes.include?(segments.first)

          route_target(namespace_segments(segments))
        end

        # Consume segments until the resource path begins. `-` is itself a wildcard
        # route, so the /-/ separator needs no special case.
        def namespace_segments(segments)
          route = []

          segments.each_with_index do |segment, index|
            break if segment.empty? || reserved_at?(segments, index, segment)

            if segment.end_with?(GIT_SUFFIX)
              repo = strip_repo_suffix(segment.delete_suffix(GIT_SUFFIX))
              route << repo unless repo.empty?
              break
            end

            route << segment
          end

          route
        end

        # A wiki or design repo is the project's, so its traffic belongs in the project's
        # bucket. Only reached from the .git branch: `.wiki` is a legal project path, so
        # a web request for a project actually named that keeps its own key.
        def strip_repo_suffix(segment)
          suffix = repo_suffixes.find { |candidate| segment.end_with?(candidate) }
          return segment unless suffix

          segment.delete_suffix(suffix)
        end

        def repo_suffixes
          @repo_suffixes ||= ::Gitlab::GlRepository.types.values
            .filter_map { |type| type.path_suffix.presence }
            .freeze
        end

        # A multi-segment wildcard such as `info/lfs/objects` reserves only the whole
        # sequence, so `info` alone stays a legal namespace and must not cut the route.
        # Keyed by first word so the common segment costs one hash miss, not a slice
        # per multi-segment wildcard.
        def reserved_at?(segments, index, segment)
          return true if single_segment_wildcards.include?(segment)

          candidates = multi_segment_wildcards[segment]
          return false unless candidates

          candidates.any? { |words| segments[index, words.length] == words }
        end

        def top_level_routes
          @top_level_routes ||= ::Gitlab::PathRegex::TOP_LEVEL_ROUTES.to_set.freeze
        end

        def single_segment_wildcards
          @single_segment_wildcards ||= wildcards.reject { |route| route.include?('/') }.to_set.freeze
        end

        def multi_segment_wildcards
          @multi_segment_wildcards ||= wildcards
            .filter_map { |route| route.split('/') if route.include?('/') }
            .group_by(&:first)
            .freeze
        end

        def wildcards
          ::Gitlab::PathRegex::PROJECT_WILDCARD_ROUTES
        end

        # A root namespace, its Namespace::NUMBER_OF_ANCESTORS_ALLOWED subgroups, then
        # the project. A path longer than that names no route, so it is rejected rather
        # than truncated to a wrong key.
        def max_route_segments
          @max_route_segments ||= ::Namespace::NUMBER_OF_ANCESTORS_ALLOWED + 2
        end
      end
    end
  end
end

::Gitlab::RateLimit::TargetKey.prepend_mod
