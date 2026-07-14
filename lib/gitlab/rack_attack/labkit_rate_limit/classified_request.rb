# frozen_string_literal: true

module Gitlab
  module RackAttack
    module LabkitRateLimit
      # A request that classifies itself for Labkit::RateLimit independently of
      # Rack::Attack. It is the same shape as Rack::Attack::Request (a Rack::Request
      # with Gitlab::RackAttack::Request mixed in), so the low-level request
      # primitives (logical_path, frontend_request?, unauthenticated?,
      # authenticated_identifier, ...) and the auth path behave identically to the
      # legacy stack, but it carries no dependency on the Rack::Attack gem. It does
      # not call throttled_identifer: the requester discriminator is computed here
      # from the auth primitive and exposed as explicit (id, type) facts.
      #
      # #labkit_facts exposes the request as a flat context the Labkit rules match
      # on (see Limiters / ThrottleRegistry). It deliberately does not call the
      # Rack::Attack throttle_*? predicates: a throttle's applicability is expressed
      # as an ordered Labkit rule whose matcher operates on these facts, not echoed
      # from the predicate. The facts are the raw building blocks the rules combine:
      #
      #   - identity values (ip, requester_id/type, runner_id, aid, path, method) are
      #     what a rule counts by, what path/method matchers compare, and the auth-state
      #     presence facts rules gate on; never coerced.
      #   - classification facts are booleans a rule matches on (the handful of
      #     conditions that cannot be a static path matcher), coerced to strict
      #     true/false.
      #   - setting_* facts mirror the per-throttle admin enable settings, matched
      #     by each rule so an admin toggling a throttle takes effect immediately
      #     (the rule stops matching and the request falls through to the next rule
      #     in order), without rebuilding the limiter.
      #
      # Most throttle conditions that used to be derived booleans (api/git/packages/
      # files paths) are now expressed directly as { path: { re: REGEX } } matchers
      # in the registry, so they do not appear here. Auth state is the requester_id /
      # runner_id presence facts. What remains as classification facts are the
      # conditions a matcher cannot express: the web/frontend disjunction, the
      # admin-dynamic protected-path match, and the param-derived deprecated condition.
      class ClassifiedRequest < ::Rack::Request
        include ::Gitlab::RackAttack::Request

        def labkit_facts
          identity_facts.merge(classification_facts.transform_values { |value| !!value })
        end

        private

        # Identity / discriminator and matcher-input values. Never coerced: a rule
        # counts by the identity values and the path/method matchers compare them as
        # String. `path` is the logical path (relative-URL-root prefix stripped, as
        # Gitlab::RackAttack::Request#matches? does), so the registry path regexes
        # match correctly on a self-managed install mounted under a relative URL.
        #
        # The requester is resolved once with the widest format list ([:api, :rss,
        # :ics]) and shared by every rule. The api throttles used to resolve it with
        # [:api] only, but on an api path the two agree: rss/ics auth needs an
        # .atom/.ics path (or format), which api routes are not, so the extra formats
        # are inert there. requester_id/runner_id are the two auth-state presence
        # facts: requester_id present is an authenticated user/deploy/job-user,
        # runner_id present is a runner, and both nil is unauthenticated? (see the
        # unauthenticated rules' `requester_id: nil, runner_id: nil` guard).
        def identity_facts
          requester = requester([:api, :rss, :ics])

          {
            ip: ip,
            requester_id: requester[:id],
            requester_type: requester[:type],
            runner_id: runner_id,
            aid: params['aid'],
            path: logical_path,
            method: request_method
          }
        end

        # The requester discriminator as an explicit { id:, type: } pair, computed
        # without Gitlab::RackAttack::Request#throttled_identifer so this classifier
        # carries no dependency on the throttle-identifier-string method. It reuses
        # the lower-level auth primitive #authenticated_identifier (a pure auth
        # lookup with no throttle semantics and no side effects), then applies the
        # one throttle concern that lives in throttled_identifer and must be
        # preserved: an allowlisted user is exempt from the identity throttles.
        #
        # requester_id is tri-state, so allowlisted is distinct from anonymous:
        #   - a real id  -> counted by the authenticated rules (requester_id: /./);
        #   - nil        -> anonymous, matched by the unauthenticated rules
        #                   (requester_id: nil), which throttle by IP;
        #   - '' (blank) -> allowlisted: matches neither the presence gate (/./ needs a
        #                   character) nor the nil gate (nil == '' is false), so no
        #                   identity throttle counts it. A still-nil id here would make
        #                   the allowlisted user look anonymous and be IP-throttled,
        #                   because unauthenticated? is false for them (they ARE
        #                   authenticated). Collector-style throttles that key off aid,
        #                   not the requester, still apply, mirroring Rack::Attack
        #                   (whose allowlist only nils throttled_identifer, leaving the
        #                   aid-keyed collector to fire).
        #
        # The id is stringified: requester.id is an Integer, but the presence gate
        # (requester_id: /./) and Labkit's redis-key encoding compare it as a
        # String, and Regexp#match? raises a TypeError on an Integer (which the
        # Labkit evaluator catches and then fails open), so an unstringified id would
        # silently stop authenticated requests being throttled.
        #
        # The (type, id) pair is counted by as two ordered characteristics, which
        # Labkit joins into one redis key - equivalent to the old "type:id" string,
        # and keeping a DeployToken and a User with the same numeric id on distinct
        # counters via the type segment.
        #
        # Unlike throttled_identifer, this deliberately does NOT set
        # Gitlab::Instrumentation::Throttle.safelist for an allowlisted user: that is
        # throttle-instrumentation coupling (the thing being decoupled), and the real
        # Rack::Attack stack sets the safelist itself on the same request, so the
        # observable behavior is unchanged.
        def requester(request_formats)
          identifier = authenticated_identifier(request_formats)
          return {} unless identifier

          identifier_type = identifier[:identifier_type]
          identifier_id = identifier[:identifier_id]

          if identifier_type == :user && ::Gitlab::RackAttack.user_allowlist.include?(identifier_id)
            return { id: '', type: '' }
          end

          { id: identifier_id.to_s, type: identifier_type.to_s }
        end

        # Boolean facts a rule matches on, coerced to strict true/false in
        # #labkit_facts. EE extends this (incident management, Geo). These are only
        # the conditions a matcher cannot express directly (auth state is not here: it
        # is the requester_id / runner_id presence facts in #identity_facts):
        #   - frontend: frontend_request? (a verified CSRF token). CSRF/session-based,
        #     not a path, so it cannot be a path matcher. web_request? itself is now a
        #     path matcher (WEB_PATH_REGEX) in the registry, so there is no derived web
        #     fact: the web throttles are a WEB_PATH_REGEX rule plus a frontend
        #     companion that matches this fact (the old web_or_frontend disjunction,
        #     which Labkit's AND-only matcher cannot express, split into two rules);
        #   - protected_path: the protected-paths list is admin configured and takes
        #     effect immediately, so it cannot be baked into a static matcher regex. One
        #     method-aware fact for both the POST and GET protected-path throttles: the
        #     list to match against depends on the request method (see #protected_path?),
        #     and each rule's own `method:` gate ensures the fact was computed against the
        #     matching list;
        #   - deprecated: a path match plus the with_projects param default;
        #   - bypass: the safelist header, matched by the bypass rule.
        def classification_facts
          settings = ::Gitlab::Throttle.settings

          {
            frontend: frontend_request?, # frontend_request checks HTTP_X_CSRF_TOKEN header - not a regex
            protected_path: protected_path?,
            deprecated: deprecated_api_request?, # TODO use path matchers for deprecated API requests: https://gitlab.com/gitlab-org/ruby/gems/labkit-ruby/-/work_items/71
            bypass: labkit_bypassed?,

            # per-throttle enable settings each rule matches on (option 2: matched
            # per request so an admin change takes effect immediately)
            setting_unauthenticated_api: settings.throttle_unauthenticated_api_enabled,
            setting_authenticated_api: settings.throttle_authenticated_api_enabled,
            # TODO: legacy column name, renamed in https://gitlab.com/gitlab-org/gitlab/-/issues/340031
            setting_unauthenticated_web: settings.throttle_unauthenticated_enabled,
            setting_authenticated_web: settings.throttle_authenticated_web_enabled,
            setting_unauthenticated_packages: settings.throttle_unauthenticated_packages_api_enabled,
            setting_authenticated_packages: settings.throttle_authenticated_packages_api_enabled,
            setting_unauthenticated_files: settings.throttle_unauthenticated_files_api_enabled,
            setting_authenticated_files: settings.throttle_authenticated_files_api_enabled,
            setting_unauthenticated_deprecated: settings.throttle_unauthenticated_deprecated_api_enabled,
            setting_authenticated_deprecated: settings.throttle_authenticated_deprecated_api_enabled,
            setting_unauthenticated_git_http: settings.throttle_unauthenticated_git_http_enabled,
            setting_authenticated_git_http: settings.throttle_authenticated_git_http_enabled,
            setting_authenticated_git_lfs: settings.throttle_authenticated_git_lfs_enabled,
            setting_protected_paths: ::Gitlab::Throttle.protected_paths_enabled?
          }
        end

        # The runner registration id (stringified, so a rule comparing it never trips
        # Regexp#match?'s TypeError-on-Integer and fails open), or nil when the request
        # is not runner-authenticated. Signifies only the runner itself: a job token is
        # deliberately not folded in, so it never enters a redis counter identifier.
        # Used purely as a presence fact: a runner-authenticated request has no
        # requester, so the unauthenticated rules' `runner_id: nil` guard is what keeps
        # it out of the IP throttles (mirroring unauthenticated? accounting for runners).
        def runner_id
          request_authenticator.runner&.id&.to_s
        end

        # Combines the module's protected_path? (POST list) and
        # get_request_protected_path? (GET list) into one method-aware predicate: it
        # picks the list to match against from the request method, so a single
        # `protected_path` fact serves both the POST and GET protected-path throttles.
        # This mirrors the legacy stack, where protected_path? was always paired with
        # post? and get_request_protected_path? with get?; here each registry rule's own
        # `method:` gate provides that pairing, so the fact is only read against the
        # list its rule's method selected. protected_paths / protected_paths_for_get_request
        # and matches_protected_path? come from the Gitlab::RackAttack::Request mixin.
        def protected_path?
          matches_protected_path?(get? ? protected_paths_for_get_request : protected_paths)
        end

        def labkit_bypassed?
          header = ::Gitlab::Throttle.bypass_header
          header.present? && get_header(header) == '1'
        end
      end
    end
  end
end

::Gitlab::RackAttack::LabkitRateLimit::ClassifiedRequest.prepend_mod
