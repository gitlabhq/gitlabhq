# frozen_string_literal: true

module API
  module WorkItems
    WORK_ITEMS_TAGS = %w[work_items].freeze
    GROUP_ONLY_FILTER_PARAMS = %i[include_ancestors include_descendants include_archived].freeze
    DEFAULT_FIELDS = %i[id iid global_id title].freeze
    FULL_PATH_ID_REQUIREMENT = %r{[^/]+(?:/[^/]+)*}
    SUBSCRIPTION_STATUS_ENUM = {
      'EXPLICITLY_SUBSCRIBED' => :explicitly_subscribed,
      'EXPLICITLY_UNSUBSCRIBED' => :explicitly_unsubscribed
    }.freeze
    FIELD_NAME_LOOKUP = ::API::Entities::WorkItemBasic.root_exposures.each_with_object({}) do |exposure, hash|
      key = exposure.key
      hash[key.to_s] = key
    end.freeze
    ALL_FIELDS = FIELD_NAME_LOOKUP.values.uniq.freeze
    FAILURE_RESPONSES = [
      { code: 400, message: 'Bad request' },
      { code: 401, message: 'Unauthorized' },
      { code: 403, message: 'Forbidden - you do not have permission to perform the action, ' \
                     'or your token scope or CI/CD job token permissions do not allow it' },
      { code: 404, message: 'Not found - the resource does not exist, you cannot view it, ' \
                     'or the work_item_rest_api feature flag is disabled' }
    ].freeze

    FEATURE_NAME_LOOKUP = ::API::Entities::WorkItems::Features::Entity
      .root_exposures
      .each_with_object({}) do |exposure, hash|
        key = exposure.key.to_sym
        hash[key.to_s] = key
      end.freeze

    FEATURE_SUPPORTED_VALUES = FEATURE_NAME_LOOKUP.keys.freeze

    # Features that only the EE entity exposes. CE must still accept them on read endpoints and omit
    # them, like an unlicensed EE namespace does, instead of returning 400.
    EE_ONLY_FEATURE_NAMES = %w[
      color
      custom_fields
      health_status
      iteration
      linked_items
      progress
      requirement_legacy
      status
      verification_status
      weight
    ].freeze

    KNOWN_FEATURE_NAMES = (FEATURE_SUPPORTED_VALUES + EE_ONLY_FEATURE_NAMES).uniq.freeze
  end
end
