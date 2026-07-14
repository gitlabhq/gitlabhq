# frozen_string_literal: true

module Gitlab
  module RackAttack
    module LabkitRateLimit
      # The explicit, ordered list of Labkit rules that replace the Rack::Attack
      # request throttles, grouped by limiter. Each throttle maps to one rule:
      #
      #   :limiter        which Limiter owns the rule. Throttles that co-fire with a
      #                   general throttle (protected paths, EE incident management)
      #                   get their own limiter so both counters increment, mirroring
      #                   Rack::Attack evaluating every throttle.
      #   :match          the Labkit rule match: a hash of facts that must all hold.
      #                   Built from the raw facts ClassifiedRequest exposes - path
      #                   regexes, the HTTP method, the auth-state presence facts, and
      #                   the per-throttle enable setting - never from the throttle_*?
      #                   predicate. Auth state is two id-presence facts: an
      #                   authenticated rule gates on { requester_id => /./ }, an
      #                   unauthenticated rule on { requester_id => nil, runner_id => nil }
      #                   (unauthenticated? is exactly no-requester-and-no-runner). The
      #                   match carries no negations: a general throttle does not
      #                   exclude the specialized ones it overlaps; instead the rules
      #                   are ordered specialized-before-general and Labkit's
      #                   first-match-wins evaluation lets the specialized rule claim
      #                   the request, exactly as Rack::Attack's hand-written
      #                   `!throttle_packages? && ...` exclusions do.
      #   :characteristics the identifier slots the rule counts by, as the array the
      #                   SDK's Rule expects. Labkit joins them in order into the redis
      #                   counter key, so an authenticated rule counts by the
      #                   (requester_type, requester_id) pair - one counter per
      #                   requester, with a DeployToken and a User of the same numeric
      #                   id kept distinct by the type segment. The requester is
      #                   resolved once with [:api, :rss, :ics] and shared by the api
      #                   and web rules (they agree on api paths, where rss/ics auth is
      #                   inert). :ip and :path are always present; :requester_id and
      #                   :aid are nil for an unauthenticated (or non-collector, or
      #                   allowlisted) request, so a rule that counts by one carries a
      #                   presence gate on the id ({ requester_id => /./ }, { aid => /./ })
      #                   in its :match, which suppresses it when the value is absent -
      #                   mirroring the Rack::Attack lambda returning nil.
      #   :cohort         drives the per-cohort enforce flag. Cohort gates enforcement
      #                   only: every rule is always built (universal presence), so
      #                   an inactive cohort still classifies and counts but its block
      #                   does not become a 429.
      #
      # Order within a limiter is load-bearing (it encodes the exclusions): the hash
      # is insertion-ordered and Limiters builds rules in that order. The order is
      # specialized API -> git -> web -> general API, so a packages request is claimed
      # by the packages rule before the general API rule, a frontend request (an API
      # path the web throttle owns) is claimed by the web rule before the API rule,
      # and a git request (which is also a web request) is claimed by a git rule
      # before the web rule.
      #
      # A spec asserts meta covers every throttle in all_throttle_definitions, so a
      # newly added Rack::Attack throttle cannot silently escape the middleware.
      module ThrottleRegistry
        GENERAL = 'rack_request'
        PROTECTED = 'rack_request_protected_paths'

        COLLECTOR_PATH_REGEX = %r{^/-/collector/i}

        # API_PATH_REGEX is `^/api/|/oauth/` - `/api/` is start-anchored but `/oauth/`
        # matches anywhere - and the health family is start-anchored. MULTILINE so the
        # unanchored `/oauth/` scan crosses newlines exactly as the predicate's
        # #match? does.
        WEB_PATH_REGEX = Regexp.new(
          '\A(?!.*/oauth/)(?!/api/)(?!/-/(?:health|liveness|readiness|metrics))',
          Regexp::MULTILINE
        )

        # :name is the backing Rack::Attack throttle (definition, dry-run state, 429
        # header name); :rule_name is the unique Labkit rule / counter name. They differ
        # only for a sibling rule that shares another throttle (the web frontend
        # companions): name is the shared throttle, rule_name the companion's own.
        Entry = Struct.new(
          :name, :limiter, :rule_name, :characteristics, :match, :cohort, :definition,
          keyword_init: true
        )

        class << self
          # The static throttle metadata, keyed by throttle name, in rule order.
          # Memoized: the matches are static (the path regexes are resolved once
          # here rather than per request, and rather than at file-load time since
          # this file is autoloaded). Exposed as a method so EE can merge in its own
          # middleware throttles; see
          # ee/lib/ee/gitlab/rack_attack/labkit_rate_limit/throttle_registry.rb.
          def meta
            @meta ||= build_meta
          end

          # name => Entry, merging the static metadata with the live Rack::Attack
          # definition (options for limit/period). Built per call so
          # admin-setting-driven limits and test stubs of the throttle source
          # propagate, mirroring how Stage 2a rebuilds rules per check.
          def all
            definitions = ::Gitlab::RackAttack.all_throttle_definitions

            meta.each_with_object({}) do |(rule_id, attrs), entries|
              # A sibling rule sharing another throttle's limit/cohort/settings (the
              # web frontend companions) names its backing throttle in :throttle; every
              # other entry backs the throttle its key names.
              throttle = attrs[:throttle] || rule_id
              definition = definitions.fetch(throttle) do
                raise KeyError, "LabkitRateLimit registry references unknown throttle #{throttle.inspect}"
              end

              entries[rule_id] = Entry.new(
                name: throttle,
                rule_name: rule_name_for(rule_id),
                definition: definition,
                **attrs.except(:throttle)
              )
            end
          end

          # The distinct cohorts, ascending. Read from the static metadata so the
          # middleware can check which cohort enforce flags are on without building
          # the full (definition-merged) registry.
          def cohorts
            # rubocop:disable Rails/Pluck -- meta is a plain Hash, not an ActiveRecord relation
            meta.values.map { |attrs| attrs[:cohort] }.uniq.sort
            # rubocop:enable Rails/Pluck
          end

          # Entries grouped by limiter, preserving rule order, for building each
          # Limiter's rule set.
          def by_limiter
            all.values.group_by(&:limiter)
          end

          # Every rule name mapped to its Entry. Each registry entry is exactly one
          # Labkit rule, so this is all re-keyed by rule_name. The middleware resolves a
          # matched rule to its throttle here - for the enforce cohort (Entry#cohort)
          # and the 429 headers (Entry#name, the backing throttle) - so a companion,
          # whose rule_name is not itself a throttle name, still resolves correctly.
          def by_rule_name
            all.values.index_by(&:rule_name)
          end

          # The shadow/enforce feature-flag basis for a cohort, mirroring Stage
          # 2a's flag_scope convention but namespaced so it cannot collide with
          # the ApplicationRateLimiter cohorts.
          def flag_basis(cohort)
            "rack_cohort_#{cohort}"
          end

          # Labkit rule and limiter names must match /\A[a-z0-9_]+\z/. Throttle
          # names already satisfy this once the redundant `throttle_` prefix is
          # dropped (the limiter name already conveys these are request throttles).
          def rule_name_for(throttle_name)
            throttle_name.delete_prefix('throttle_')
          end

          # The should_be_skipped? decomposition, as named skip matches. Each becomes a
          # terminating :allow rule (see Limiters), gated on the request being
          # unauthenticated (requester_id and runner_id both nil) so an authenticated
          # request to an internal/health path is still throttled - exactly as
          # Rack::Attack, whose !should_be_skipped? sits only in the unauthenticated
          # throttles. The path skips (internal API, health, container registry) are one
          # path matcher; EE unions the virtual-registry endpoints into that path and
          # adds a verified_geo_request skip for the JWT-gated geo requests, which cannot
          # be a path matcher.
          def skip_matches
            request = ::Gitlab::RackAttack::Request

            {
              'skip_internal_api' => { path: request::API_INTERNAL_PATH_REGEX, requester_id: nil, runner_id: nil },
              'skip_health_checks' => { path: request::HEALTH_CHECK_PATH_REGEX, requester_id: nil, runner_id: nil },
              'container_registry_event_path' => {
                path: request::CONTAINER_REGISTRY_EVENT_PATH_REGEX, requester_id: nil, runner_id: nil
              }
            }
          end

          private

          def build_meta
            request = ::Gitlab::RackAttack::Request
            api = request::API_PATH_REGEX
            files = request::FILES_PATH_REGEX
            packages = ::Gitlab::Regex::Packages::API_PATH_REGEX
            git = ::Gitlab::PathRegex.repository_git_route_regex
            git_lfs = ::Gitlab::PathRegex.repository_git_lfs_route_regex

            {
              # Cohort 1: specialized APIs (product analytics, packages, files,
              # deprecated). Ordered first so they claim their requests before the
              # general API rule. Lowest risk.
              'throttle_product_analytics_collector' => {
                limiter: GENERAL, characteristics: [:aid], cohort: 1,
                match: { path: COLLECTOR_PATH_REGEX, aid: /./ }
              },
              'throttle_unauthenticated_packages_api' => {
                limiter: GENERAL, characteristics: [:ip], cohort: 1,
                match: { path: packages, requester_id: nil, runner_id: nil, setting_unauthenticated_packages: true }
              },
              'throttle_authenticated_packages_api' => {
                limiter: GENERAL, characteristics: [:requester_type, :requester_id], cohort: 1,
                match: { path: packages, setting_authenticated_packages: true, requester_id: /./ }
              },
              'throttle_unauthenticated_files_api' => {
                limiter: GENERAL, characteristics: [:ip], cohort: 1,
                match: { path: files, requester_id: nil, runner_id: nil, setting_unauthenticated_files: true }
              },
              'throttle_authenticated_files_api' => {
                limiter: GENERAL, characteristics: [:requester_type, :requester_id], cohort: 1,
                match: { path: files, setting_authenticated_files: true, requester_id: /./ }
              },
              'throttle_unauthenticated_deprecated_api' => {
                limiter: GENERAL, characteristics: [:ip], cohort: 1,
                match: { deprecated: true, requester_id: nil, runner_id: nil, setting_unauthenticated_deprecated: true }
              },
              'throttle_authenticated_deprecated_api' => {
                limiter: GENERAL, characteristics: [:requester_type, :requester_id], cohort: 1,
                match: { deprecated: true, setting_authenticated_deprecated: true, requester_id: /./ }
              },

              # Cohort 3: git over HTTP / LFS. Ordered before the web rules because a
              # git request is also a web request, and git_lfs before git_http so a
              # non-LFS git request falls through to git_http. Promoted last (cohort
              # 3) alongside protected paths.
              'throttle_authenticated_git_lfs' => {
                limiter: GENERAL, characteristics: [:requester_type, :requester_id], cohort: 3,
                match: { path: git_lfs, setting_authenticated_git_lfs: true, requester_id: /./ }
              },
              'throttle_authenticated_git_http' => {
                limiter: GENERAL, characteristics: [:requester_type, :requester_id], cohort: 3,
                match: { path: git, setting_authenticated_git_http: true, requester_id: /./ }
              },
              'throttle_unauthenticated_git_http' => {
                limiter: GENERAL, characteristics: [:ip], cohort: 3,
                match: { path: git, requester_id: nil, runner_id: nil, setting_unauthenticated_git_http: true }
              },

              # Cohort 2: general web then general API. Web before API so a frontend
              # request (an API path the web throttle owns) is claimed here, not by the
              # API rule. Each web throttle is two rules - a web-path rule
              # (path: WEB_PATH_REGEX, the native form of the removed web_request?
              # predicate) and a frontend companion (the CSRF-token frontend fact) -
              # because "web OR frontend" is a disjunction a single AND-match cannot
              # express and each rule keys its counter by its unique name. The companion
              # is a sibling entry backing the same throttle (:throttle), placed
              # immediately after its web-path rule and before the API rules so it
              # claims frontend requests on API paths first.
              'throttle_unauthenticated_web' => {
                limiter: GENERAL, characteristics: [:ip], cohort: 2,
                match: { path: WEB_PATH_REGEX, requester_id: nil, runner_id: nil, setting_unauthenticated_web: true }
              },
              'throttle_unauthenticated_web_frontend' => {
                throttle: 'throttle_unauthenticated_web',
                limiter: GENERAL, characteristics: [:ip], cohort: 2,
                match: { frontend: true, requester_id: nil, runner_id: nil, setting_unauthenticated_web: true }
              },
              'throttle_authenticated_web' => {
                limiter: GENERAL, characteristics: [:requester_type, :requester_id], cohort: 2,
                match: { path: WEB_PATH_REGEX, setting_authenticated_web: true, requester_id: /./ }
              },
              'throttle_authenticated_web_frontend' => {
                throttle: 'throttle_authenticated_web',
                limiter: GENERAL, characteristics: [:requester_type, :requester_id], cohort: 2,
                match: { frontend: true, setting_authenticated_web: true, requester_id: /./ }
              },
              'throttle_unauthenticated_api' => {
                limiter: GENERAL, characteristics: [:ip], cohort: 2,
                match: { path: api, requester_id: nil, runner_id: nil, setting_unauthenticated_api: true }
              },
              'throttle_authenticated_api' => {
                limiter: GENERAL, characteristics: [:requester_type, :requester_id], cohort: 2,
                match: { path: api, setting_authenticated_api: true, requester_id: /./ }
              },

              # Cohort 3: protected paths. Their own limiter (they overlap the general
              # throttles and Rack::Attack counts the request under both). POST and GET
              # variants split by method; api/web split by the api path regex / the
              # web path regex (WEB_PATH_REGEX, the native form of web_request?).
              'throttle_unauthenticated_protected_paths' => {
                limiter: PROTECTED, characteristics: [:ip], cohort: 3,
                match: {
                  method: 'POST', protected_path: true, requester_id: nil, runner_id: nil,
                  setting_protected_paths: true
                }
              },
              'throttle_authenticated_protected_paths_api' => {
                limiter: PROTECTED, characteristics: [:requester_type, :requester_id], cohort: 3,
                match: {
                  method: 'POST', path: api, protected_path: true, setting_protected_paths: true, requester_id: /./
                }
              },
              'throttle_authenticated_protected_paths_web' => {
                limiter: PROTECTED, characteristics: [:requester_type, :requester_id], cohort: 3,
                match: {
                  method: 'POST', path: WEB_PATH_REGEX, protected_path: true, setting_protected_paths: true,
                  requester_id: /./
                }
              },
              'throttle_unauthenticated_get_protected_paths' => {
                limiter: PROTECTED, characteristics: [:ip], cohort: 3,
                match: {
                  method: 'GET', protected_path: true, requester_id: nil, runner_id: nil,
                  setting_protected_paths: true
                }
              },
              'throttle_authenticated_get_protected_paths_api' => {
                limiter: PROTECTED, characteristics: [:requester_type, :requester_id], cohort: 3,
                match: {
                  method: 'GET', path: api, protected_path: true, setting_protected_paths: true,
                  requester_id: /./
                }
              },
              'throttle_authenticated_get_protected_paths_web' => {
                limiter: PROTECTED, characteristics: [:requester_type, :requester_id], cohort: 3,
                match: {
                  method: 'GET', path: WEB_PATH_REGEX, protected_path: true, setting_protected_paths: true,
                  requester_id: /./
                }
              }
            }.freeze
          end
        end
      end
    end
  end
end

::Gitlab::RackAttack::LabkitRateLimit::ThrottleRegistry.prepend_mod
