# frozen_string_literal: true

# This file can contain only simple constructs as it is shared between:
# 1. `Pure Ruby`: `bin/feature-flag`
# 2. `GitLab Rails`: `lib/feature/definition.rb`

module Feature
  module Shared
    # optional: defines if a on-disk definition is required for this feature flag type
    # rollout_issue: defines if `bin/feature-flag` asks for rollout issue
    # can_be_default_enabled: whether the flag can have `default_enabled` set to `true` or not
    # deprecated: defines if a feature flag type that is deprecated and to be removed,
    #             the deprecated types are hidden from all interfaces
    # example: usage being shown when exception is raised
    TYPES = {
      gitlab_com_derisk: {
        description: 'Short lived, used to de-risk GitLab.com deployments',
        optional: false,
        rollout_issue: true,
        can_be_default_enabled: false,
        example: <<~EOS
          Feature.enabled?(:my_feature_flag, project, type: :gitlab_com_derisk)
          push_frontend_feature_flag(:my_feature_flag, project)
        EOS
      },
      wip: {
        description: 'Used to hide unfinished code from anyone',
        optional: false,
        rollout_issue: false,
        can_be_default_enabled: false,
        example: <<~EOS
          Feature.enabled?(:my_feature_flag, project, type: :wip)
          push_frontend_feature_flag(:my_feature_flag, project)
        EOS
      },
      beta: {
        description: "Use when we aren't confident about scaling/supporting a feature, " \
                     "or when it isn't complete enough for an MVC",
        optional: false,
        rollout_issue: true,
        can_be_default_enabled: true,
        example: <<~EOS
          Feature.enabled?(:my_feature_flag, project, type: :beta)
          push_frontend_feature_flag(:my_feature_flag, project)
        EOS
      },
      ops: {
        description: "Long-lived feature flags that control operational aspects of GitLab's behavior",
        optional: false,
        rollout_issue: true,
        can_be_default_enabled: true,
        example: <<~EOS
          Feature.enabled?(:my_ops_flag, type: :ops)
          push_frontend_feature_flag(:my_ops_flag, project, type: :ops)
        EOS
      },
      experiment: {
        description: 'Short lived, used specifically to run A/B/n experiments.',
        optional: true,
        rollout_issue: true,
        can_be_default_enabled: false,
        example: <<~EOS
          experiment(:my_experiment, project: project, actor: current_user) { ...variant code... }
        EOS
      },
      worker: {
        description: "Feature flags for controlling Sidekiq workers behavior (e.g. deferring jobs)",
        optional: true,
        rollout_issue: false,
        can_be_default_enabled: false,
        example: <<~EOS
          Feature.enabled?(:"defer_sidekiq_jobs:AuthorizedProjectsWorker", type: :worker,
            default_enabled_if_undefined: false)
        EOS
      },
      undefined: {
        description: "Feature flags that are undefined in GitLab codebase (should not be used)",
        optional: true,
        rollout_issue: false,
        can_be_default_enabled: false,
        example: ''
      },
      development: {
        deprecated: true,
        can_be_default_enabled: true
      }
    }.freeze

    # The ordering of PARAMS defines an order in YAML
    # This is done to ease the file comparison
    PARAMS = %i[
      name
      feature_issue_url
      introduced_by_url
      rollout_issue_url
      milestone
      log_state_changes
      type
      group
      default_enabled
    ].freeze

    def self.can_be_default_enabled?(feature_flag_type)
      TYPES.dig(feature_flag_type.to_sym, :can_be_default_enabled)
    end
  end
end
