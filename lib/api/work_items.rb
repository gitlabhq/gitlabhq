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
      { code: 403, message: 'Forbidden - feature flag disabled' },
      { code: 404, message: 'Not found' }
    ].freeze

    FEATURE_NAME_LOOKUP = ::API::Entities::WorkItems::Features::Entity
      .root_exposures
      .each_with_object({}) do |exposure, hash|
        key = exposure.key.to_sym
        hash[key.to_s] = key
      end.freeze

    FEATURE_SUPPORTED_VALUES = FEATURE_NAME_LOOKUP.keys.freeze
  end
end
