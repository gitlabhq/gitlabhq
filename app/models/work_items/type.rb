# frozen_string_literal: true

# Note: initial thinking behind `icon_name` is for it to do triple duty:
# 1. one of our svg icon names, such as `external-link` or a new one `bug`
# 2. if it's an absolute url, then url to a user uploaded icon/image
# 3. an emoji, with the format of `:smile:`
module WorkItems
  class Type < ApplicationRecord
    include Gitlab::Utils::StrongMemoize
    include SafelyChangeColumnDefault

    DEFAULT_TYPES_NOT_SEEDED = Class.new(StandardError)

    self.table_name = 'work_item_types'

    include CacheMarkdownField
    include ReactiveCaching

    self.reactive_cache_work_type = :no_dependency
    self.reactive_cache_refresh_interval = 10.minutes
    self.reactive_cache_lifetime = 1.hour

    # type name is used in restrictions DB seeder to assure restrictions for
    # default types are pre-filled
    TYPE_NAMES = {
      issue: 'Issue',
      incident: 'Incident',
      test_case: 'Test Case',
      requirement: 'Requirement',
      task: 'Task',
      objective: 'Objective',
      key_result: 'Key Result',
      epic: 'Epic',
      ticket: 'Ticket'
    }.freeze

    # Base types need to exist on the DB on app startup
    # This constant is used by the DB seeder
    # TODO - where to add new icon names created?
    BASE_TYPES = {
      issue: { name: TYPE_NAMES[:issue], icon_name: 'issue-type-issue', enum_value: 0, id: 1 },
      incident: { name: TYPE_NAMES[:incident], icon_name: 'issue-type-incident', enum_value: 1, id: 2 },
      test_case: { name: TYPE_NAMES[:test_case], icon_name: 'issue-type-test-case', enum_value: 2, id: 3 }, ## EE-only
      requirement: { name: TYPE_NAMES[:requirement], icon_name: 'issue-type-requirements', enum_value: 3, id: 4 }, ## EE
      task: { name: TYPE_NAMES[:task], icon_name: 'issue-type-task', enum_value: 4, id: 5 },
      objective: { name: TYPE_NAMES[:objective], icon_name: 'issue-type-objective', enum_value: 5, id: 6 }, ## EE-only
      key_result: { name: TYPE_NAMES[:key_result], icon_name: 'issue-type-keyresult', enum_value: 6, id: 7 }, ## EE-only
      epic: { name: TYPE_NAMES[:epic], icon_name: 'issue-type-epic', enum_value: 7, id: 8 }, ## EE-only
      ticket: { name: TYPE_NAMES[:ticket], icon_name: 'issue-type-issue', enum_value: 8, id: 9 }
    }.freeze

    # A list of types user can change between - both original and new
    # type must be included in this list. This is needed for legacy issues
    # where it's possible to switch between issue and incident.
    CHANGEABLE_BASE_TYPES = %w[issue incident test_case].freeze

    EE_BASE_TYPES = %w[objective epic key_result requirement].freeze

    columns_changing_default :id

    cache_markdown_field :description, pipeline: :single_line

    enum base_type: BASE_TYPES.transform_values { |value| value[:enum_value] }

    has_many :widget_definitions, foreign_key: :work_item_type_id, inverse_of: :work_item_type
    has_many :enabled_widget_definitions, -> { where(disabled: false) }, foreign_key: :work_item_type_id,
      inverse_of: :work_item_type, class_name: 'WorkItems::WidgetDefinition'
    has_many :child_restrictions, class_name: 'WorkItems::HierarchyRestriction', foreign_key: :parent_type_id,
      inverse_of: :parent_type
    has_many :parent_restrictions, class_name: 'WorkItems::HierarchyRestriction', foreign_key: :child_type_id,
      inverse_of: :child_type
    has_many :allowed_child_types_by_name, -> { order_by_name_asc },
      through: :child_restrictions, class_name: 'WorkItems::Type',
      foreign_key: :child_type_id, source: :child_type
    has_many :allowed_parent_types_by_name, -> { order_by_name_asc },
      through: :parent_restrictions, class_name: 'WorkItems::Type',
      foreign_key: :parent_type_id, source: :parent_type
    has_many :user_preferences,
      class_name: 'WorkItems::Types::UserPreference',
      primary_key: :correct_id,
      inverse_of: :work_item_type

    before_validation :strip_whitespace
    after_save :clear_reactive_cache!

    # TODO: review validation rules
    # https://gitlab.com/gitlab-org/gitlab/-/issues/336919
    validates :name, presence: true
    validates :name, custom_uniqueness: { unique_sql: 'TRIM(BOTH FROM lower(?))' }
    validates :name, length: { maximum: 255 }
    validates :icon_name, length: { maximum: 255 }

    scope :order_by_name_asc, -> { order(arel_table[:name].lower.asc) }
    scope :by_type, ->(base_type) { where(base_type: base_type) }
    scope :with_correct_id_and_fallback, ->(correct_ids) {
      # This shouldn't work for nil ids as we expect newer instances to have NULL values in old_id
      correct_ids = Array(correct_ids).compact
      return none if correct_ids.blank?

      where(correct_id: correct_ids).or(where(old_id: correct_ids))
    }

    def self.find_by_correct_id_with_fallback(correct_id)
      results = with_correct_id_and_fallback(correct_id)
      return results.first if results.to_a.size <= 1 # Using to_a to avoid an additional query. Loads the relationship.

      results.find { |type| type.correct_id == correct_id }
    end

    def self.default_by_type(type)
      found_type = find_by(base_type: type)
      return found_type if found_type || !WorkItems::Type.base_types.key?(type.to_s)

      error_message = <<~STRING
        Default work item types have not been created yet. Make sure the DB has been seeded successfully.
        See related documentation in
        https://docs.gitlab.com/omnibus/settings/database.html#seed-the-database-fresh-installs-only

        If you have additional questions, you can ask in
        https://gitlab.com/gitlab-org/gitlab/-/issues/423483
      STRING

      raise DEFAULT_TYPES_NOT_SEEDED, error_message
    end

    def self.default_issue_type
      default_by_type(:issue)
    end

    def self.allowed_types_for_issues
      base_types.keys.excluding('objective', 'key_result', 'epic')
    end

    # method overridden in EE to perform the corresponding checks for the Epic type
    def self.allowed_group_level_types(resource_parent)
      if Feature.enabled?(:create_group_level_work_items, resource_parent, type: :wip)
        base_types.keys.excluding('epic')
      else
        []
      end
    end

    def to_global_id
      ::Gitlab::GlobalId.build(self, id: correct_id)
    end
    # Alias necessary here as the Gem uses `alias` to define the `gid` method
    alias_method :to_gid, :to_global_id

    # resource_parent is used in EE
    def widgets(_resource_parent)
      enabled_widget_definitions.filter(&:widget_class)
    end

    def widget_classes(resource_parent)
      widgets(resource_parent).map(&:widget_class)
    end

    def supports_assignee?(resource_parent)
      widget_classes(resource_parent).include?(::WorkItems::Widgets::Assignees)
    end

    def supports_time_tracking?(resource_parent)
      widget_classes(resource_parent).include?(::WorkItems::Widgets::TimeTracking)
    end

    def default_issue?
      name == WorkItems::Type::TYPE_NAMES[:issue]
    end

    def calculate_reactive_cache
      {
        allowed_child_types_by_name: allowed_child_types_by_name,
        allowed_parent_types_by_name: allowed_parent_types_by_name
      }
    end

    def supported_conversion_types(resource_parent, user)
      type_names = supported_conversion_base_types(resource_parent, user) - [base_type]
      WorkItems::Type.by_type(type_names).order_by_name_asc
    end

    def allowed_child_types(cache: false, authorize: false, resource_parent: nil)
      cached_data = cache ? with_reactive_cache { |query_data| query_data[:allowed_child_types_by_name] } : nil

      types = cached_data || allowed_child_types_by_name

      return types unless authorize

      authorized_types(types, resource_parent, :child)
    end

    def allowed_parent_types(cache: false, authorize: false, resource_parent: nil)
      cached_data = cache ? with_reactive_cache { |query_data| query_data[:allowed_parent_types_by_name] } : nil

      types = cached_data || allowed_parent_types_by_name

      return types unless authorize

      authorized_types(types, resource_parent, :parent)
    end

    def descendant_types
      descendant_types = []
      next_level_child_types = allowed_child_types(cache: true)

      loop do
        descendant_types += next_level_child_types

        # We remove types that we've already seen to avoid circular dependencies
        next_level_child_types = next_level_child_types.flat_map do |type|
          type.allowed_child_types(cache: true)
        end - descendant_types

        break if next_level_child_types.empty?
      end

      descendant_types
    end
    strong_memoize_attr :descendant_types

    private

    def strip_whitespace
      name&.strip!
    end

    # resource_parent is used in EE
    def supported_conversion_base_types(_resource_parent, _user)
      WorkItems::Type.base_types.keys.excluding(*EE_BASE_TYPES)
    end

    # overriden in EE to check for EE-specific restrictions
    def authorized_types(types, _resource_parent, _relation)
      types
    end
  end
end

WorkItems::Type.prepend_mod
