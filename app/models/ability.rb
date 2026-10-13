# frozen_string_literal: true

class Ability
  class << self
    # Given a list of users and a project this method returns the users that can
    # read the given project.
    def users_that_can_read_project(users, project)
      preload_max_access_levels(users, project)

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
      preload_max_access_levels(users, note_parent)

      DeclarativePolicy.subject_scope do
        users.select { |u| allowed?(u, :read_internal_note, note_parent) }
      end
    end

    def users_that_can_read_confidential_issues(users, container)
      preload_max_access_levels(users, container)

      DeclarativePolicy.subject_scope do
        users.select { |u| allowed?(u, :read_confidential_issues, container) }
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
        issues.select { |issue| allowed?(user, :read_issue, issue) }
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

    # Returns an Array of Ci::Pipelines that can be read by the given user.
    #
    # pipelines - The pipelines to reduce down to those readable by the user.
    # user - The User for which to check the pipelines
    def pipelines_readable_by_user(pipelines, user = nil)
      DeclarativePolicy.user_scope do
        pipelines.select { |pipeline| allowed?(user, :read_pipeline, pipeline) }
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

      if opts[:composite_identity_check] == false ||
          !user.respond_to?(:composite_identity_enforced?) ||
          !user&.composite_identity_enforced?
        return result
      end

      result && with_composite_identity_check(user, ability, subject, **opts)
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
    # conditions (selected by 'pattern') and the cached ability checks that
    # used them, including abilities checked by other abilities through `can?`.
    #
    # `DeclarativePolicy.invalidate` does both. It deletes the conditions and
    # discards the result of every cached ability check that read them. This
    # relies on the pattern not being _under_-selective.
    def forgetting(pattern, &block)
      keys_before = ::Gitlab::SafeRequestStore.storage.keys

      yield
    ensure
      forget_all_but(keys_before, matching: pattern)
    end

    private

    # Project abilities resolve membership through ProjectTeam#max_member_access_for_user, which
    # reads from a request-scoped store. Filling that store up front collapses the per-user lookups
    # into one query, and skips users already cached so repeated bulk checks add no queries.
    def preload_max_access_levels(users, container)
      return unless container.is_a?(Project)

      container.team.max_member_access_for_user_ids(users.map(&:id))
    end

    def forget_all_but(keys_before, matching:)
      storage = ::Gitlab::SafeRequestStore.storage
      added_keys = storage.keys - keys_before

      forgotten_keys = added_keys.select do |key|
        key.is_a?(String) && key.start_with?('/dp') && key =~ matching
      end

      DeclarativePolicy.invalidate(storage, forgotten_keys)
    end

    def apply_filters_if_needed(elements, user, filters)
      filters.each do |ability, filter|
        elements = filter.call(elements) unless allowed?(user, ability)
      end

      elements
    end

    def with_composite_identity_check(user, ability, subject = :global, **opts)
      check_user = find_user_for_composite_identity_check(user)

      return false if check_user.nil?

      allowed?(
        check_user,
        ability,
        subject,
        **opts.merge(composite_identity_check: false)
      )
    end

    def find_user_for_composite_identity_check(user)
      return Gitlab::Auth::Identity.find_primary_user_by_scoped_user_id(user.id) unless user.service_account?

      identity = ::Gitlab::Auth::Identity.fabricate(user)
      return unless identity&.valid?

      identity.scoped_user
    end
  end
end

Ability.prepend_mod_with('AbilityPrepend')
