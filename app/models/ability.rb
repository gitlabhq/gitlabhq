# frozen_string_literal: true

class Ability
  class << self
    # Given a list of users and a project this method returns the users that can
    # read the given project.
    def users_that_can_read_project(users, project)
      DeclarativePolicy.subject_scope do
        users.select { |u| allowed?(u, :read_project, project) }
      end
    end

    # Given a list of users and a group this method returns the users that can
    # read the given group.
    def users_that_can_read_group(users, group)
      DeclarativePolicy.subject_scope do
        users.select { |u| allowed?(u, :read_group, group) }
      end
    end

    # Given a list of users and a snippet this method returns the users that can
    # read the given snippet.
    def users_that_can_read_personal_snippet(users, snippet)
      DeclarativePolicy.subject_scope do
        users.select { |u| allowed?(u, :read_snippet, snippet) }
      end
    end

    # A list of users that can read confidential notes in a project
    def users_that_can_read_internal_notes(users, note_parent)
      DeclarativePolicy.subject_scope do
        users.select { |u| allowed?(u, :read_internal_note, note_parent) }
      end
    end

    # Returns an Array of Issues that can be read by the given user.
    #
    # issues - The issues to reduce down to those readable by the user.
    # user - The User for which to check the issues
    # filters - A hash of abilities and filters to apply if the user lacks this
    #           ability
    def issues_readable_by_user(issues, user = nil, filters: {})
      issues = apply_filters_if_needed(issues, user, filters)

      DeclarativePolicy.user_scope do
        issues.select { |issue| issue.visible_to_user?(user) }
      end
    end
    alias_method :work_items_readable_by_user, :issues_readable_by_user

    # Returns an Array of MergeRequests that can be read by the given user.
    #
    # merge_requests - MRs out of which to collect MRs readable by the user.
    # user - The User for which to check the merge_requests
    # filters - A hash of abilities and filters to apply if the user lacks this
    #           ability
    def merge_requests_readable_by_user(merge_requests, user = nil, filters: {})
      merge_requests = apply_filters_if_needed(merge_requests, user, filters)

      DeclarativePolicy.user_scope do
        merge_requests.select { |mr| allowed?(user, :read_merge_request, mr) }
      end
    end

    def feature_flags_readable_by_user(feature_flags, user = nil, filters: {})
      feature_flags = apply_filters_if_needed(feature_flags, user, filters)

      DeclarativePolicy.user_scope do
        feature_flags.select { |flag| allowed?(user, :read_feature_flag, flag) }
      end
    end

    def allowed?(user, ability, subject = :global, **opts)
      if subject.is_a?(Hash)
        opts = subject
        subject = :global
      end

      policy = policy_for(user, subject, **opts.slice(:cache))

      before_check(policy, ability.to_sym, user, subject, opts)

      result = case opts[:scope]
               when :user
                 DeclarativePolicy.user_scope { policy.allowed?(ability) }
               when :subject
                 DeclarativePolicy.subject_scope { policy.allowed?(ability) }
               else
                 policy.allowed?(ability)
               end

      identity = ::Gitlab::Auth::Identity.fabricate(user)

      if identity.present? && identity.composite?
        return false unless identity.valid?

        result && allowed?(identity.scoped_user, ability, subject, **opts)
      else
        result
      end

    ensure
      # TODO: replace with runner invalidation:
      # See: https://gitlab.com/gitlab-org/declarative-policy/-/merge_requests/24
      # See: https://gitlab.com/gitlab-org/declarative-policy/-/merge_requests/25
      forget_runner_result(policy.runner(ability)) if policy && ability_forgetting?
    end

    # Hook call right before ability check.
    def before_check(policy, ability, user, subject, opts)
      # See Support::AbilityCheck and Support::PermissionsCheck.
    end

    # We cache in the request store by default. This can lead to unexpected
    # results if abilities are re-checked after objects are modified and the
    # check depends on the modified attributes. In such cases, you should pass
    # `cache: false` for the second check to ensure all rules get re-evaluated.
    def policy_for(user, subject = :global, cache: true)
      policy_cache = cache ? ::Gitlab::SafeRequestStore.storage : {}

      DeclarativePolicy.policy_for(user, subject, cache: policy_cache)
    end

    # This method is something of a band-aid over the problem. The problem is
    # that some conditions may not be re-entrant, if facts change.
    # (`BasePolicy#admin?` is a known offender, due to the effects of
    # `admin_mode`)
    #
    # To deal with this we need to clear two elements of state: the offending
    # conditions (selected by 'pattern') and the cached ability checks (cached
    # on the `policy#runner(ability)`).
    #
    # Clearing the conditions (see `forget_all_but`) is fairly robust, provided
    # the pattern is not _under_-selective. Clearing the runners is harder,
    # since there is not good way to know which abilities any given condition
    # may affect. The approach taken here (see `forget_runner_result`) is to
    # discard all runner results generated during a `forgetting` block. This may
    # be _under_-selective if a runner prior to this block cached a state value
    # that might now be invalid.
    #
    # TODO: add some kind of reverse-dependency mapping in DeclarativePolicy
    # See: https://gitlab.com/gitlab-org/declarative-policy/-/issues/14
    def forgetting(pattern, &block)
      was_forgetting = ability_forgetting?
      ::Gitlab::SafeRequestStore[:ability_forgetting] = true
      keys_before = ::Gitlab::SafeRequestStore.storage.keys

      yield
    ensure
      ::Gitlab::SafeRequestStore[:ability_forgetting] = was_forgetting
      forget_all_but(keys_before, matching: pattern)
    end

    private

    def ability_forgetting?
      ::Gitlab::SafeRequestStore[:ability_forgetting]
    end

    def forget_all_but(keys_before, matching:)
      keys_after = ::Gitlab::SafeRequestStore.storage.keys

      added_keys = keys_after - keys_before
      added_keys.each do |key|
        ::Gitlab::SafeRequestStore.delete(key) if key.is_a?(String) && key.start_with?('/dp') && key =~ matching
      end
    end

    def forget_runner_result(runner)
      # TODO: add support in DP for this
      # See: https://gitlab.com/gitlab-org/declarative-policy/-/issues/15
      runner.instance_variable_set(:@state, nil)
    end

    def apply_filters_if_needed(elements, user, filters)
      filters.each do |ability, filter|
        elements = filter.call(elements) unless allowed?(user, ability)
      end

      elements
    end
  end
end

Ability.prepend_mod_with('AbilityPrepend')
