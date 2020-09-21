# frozen_string_literal: true

# This file can contain only simple constructs as it is shared between:
# 1. `Pure Ruby`: `bin/feature-flag`
# 2. `GitLab Rails`: `lib/feature/definition.rb`

class Feature
  module Shared
    # optional: defines if a on-disk definition is required for this feature flag type
    # rollout_issue: defines if `bin/feature-flag` asks for rollout issue
    # default_enabled: defines a default state of a feature flag when created by `bin/feature-flag`
    # example: usage being shown when exception is raised
    TYPES = {
      development: {
        description: 'Short lived, used to enable unfinished code to be deployed',
        optional: false,
        rollout_issue: true,
        default_enabled: false,
        example: <<-EOS
          Feature.enabled?(:my_feature_flag, project)
          Feature.enabled?(:my_feature_flag, project, type: :development)
          push_frontend_feature_flag?(:my_feature_flag, project)
        EOS
      },
      ops: {
        description: "Long-lived feature flags that control operational aspects of GitLab's behavior",
        optional: true,
        rollout_issue: false,
        default_enabled: false,
        example: <<-EOS
          Feature.enabled?(:my_ops_flag, type: ops)
          push_frontend_feature_flag?(:my_ops_flag, project, type: :ops)
        EOS
      },
      licensed: {
        description: 'Permanent feature flags used to temporarily disable licensed features.',
        optional: true,
        rollout_issue: false,
        default_enabled: true,
        example: <<-EOS
          project.feature_available?(:my_licensed_feature)
          namespace.feature_available?(:my_licensed_feature)
        EOS
      }
    }.freeze

    PARAMS = %i[
      name
      introduced_by_url
      rollout_issue_url
      type
      group
      default_enabled
    ].freeze
  end
end
